require "test_helper"
require "open3"
require "tmpdir"
require "yaml"

class IosTestflightWorkflowTest < ActiveSupport::TestCase
  REQUIRED_SECRETS = %w[
    IOS_KEYCHAIN_PASSWORD
    IOS_DISTRIBUTION_P12_BASE64
    IOS_DISTRIBUTION_P12_PASSWORD
    IOS_PROVISIONING_PROFILE_BASE64
    IOS_PROVISIONING_PROFILE_NAME
    IOS_TEAM_ID
    IOS_DISTRIBUTION_CERT_NAME
    APP_STORE_CONNECT_API_KEY_ID
    APP_STORE_CONNECT_API_KEY_BASE64
    APP_STORE_CONNECT_API_ISSUER_ID
  ].freeze

  test "manual releases require an explicit version" do
    source = Rails.root.join(".github/workflows/ios-testflight.yml").read
    assert_match(/workflow_dispatch:\n\s+inputs:\n\s+app_version:.*?\n\s+required: true/m, source)
  end

  test "preflight fails closed and names every missing secret" do
    output, status, summary = run_preflight("APP_VERSION_INPUT" => "2026.11.14")

    assert_not status.success?
    REQUIRED_SECRETS.each do |name|
      assert_includes output, "Missing required TestFlight secret: #{name}"
      assert_includes summary, "`#{name}`"
    end
  end

  test "preflight normalizes a configured release before macOS work" do
    env = REQUIRED_SECRETS.index_with { "configured-for-test" }.merge(
      "APP_VERSION_INPUT" => "v2026.11.14-alpha",
      "APP_BUNDLE_ID" => "am.sure.mobile"
    )
    output, status, = run_preflight(env)

    assert status.success?, output
    assert_includes output, "ios_version=2026.11.14\n"
    assert_includes output, "bundle_id=am.sure.mobile\n"

    job = workflow.fetch("jobs").fetch("build-and-upload")
    assert_equal [ "validate-release" ], job.fetch("needs")
    assert_equal "needs.validate-release.outputs.eligible == 'true'", job.fetch("if")
    build = job.fetch("steps").find { |step| step["name"] == "Build signed IPA" }
    assert_equal "${{ needs.validate-release.outputs.ios_version }}", build.fetch("env").fetch("IOS_VERSION")
    assert_equal "${{ needs.validate-release.outputs.bundle_id }}", build.fetch("env").fetch("APP_BUNDLE_ID")
  end

  test "configured workflow uploads and retains the same IPA then always cleans up" do
    steps = workflow.fetch("jobs").fetch("build-and-upload").fetch("steps")
    upload = steps.find { |step| step["name"] == "Upload IPA to TestFlight" }.fetch("run")
    artifact = steps.find { |step| step["name"] == "Upload build artifact" }
    cleanup = steps.find { |step| step["name"] == "Cleanup signing keychain" }

    assert_includes upload, "xcrun altool"
    assert_includes upload, "--upload-app"
    assert_equal "mobile/build/ios/ipa/*.ipa", artifact.fetch("with").fetch("path")
    assert_equal "error", artifact.fetch("with").fetch("if-no-files-found")
    assert_equal "${{ always() }}", cleanup.fetch("if")
    assert_includes cleanup.fetch("run"), "security delete-keychain"
    assert_includes cleanup.fetch("run"), "rm -f \"$KEY_FILE\""
    assert_includes cleanup.fetch("run"), "rm -f \"$RUNNER_TEMP/distribution.p12\""
    assert_includes cleanup.fetch("run"), "rm -f \"$PROFILE_PATH\""
  end

  private
    def workflow
      @workflow ||= YAML.load_file(Rails.root.join(".github/workflows/ios-testflight.yml"))
    end

    def run_preflight(overrides)
      step = workflow.fetch("jobs").fetch("validate-release").fetch("steps")
        .find { |candidate| candidate["name"] == "Validate TestFlight configuration" }
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "output")
        summary_path = File.join(dir, "summary")
        env = {
          "APP_VERSION_INPUT" => "",
          "APP_BUNDLE_ID" => "am.sure.mobile",
          "GITHUB_REF_TYPE" => "branch",
          "GITHUB_REF_NAME" => "main",
          "GITHUB_OUTPUT" => output_path,
          "GITHUB_STEP_SUMMARY" => summary_path
        }.merge(overrides)
        output, status = Open3.capture2e(env, "bash", "-c", step.fetch("run"))
        workflow_output = File.exist?(output_path) ? File.read(output_path) : ""
        summary = File.exist?(summary_path) ? File.read(summary_path) : ""
        [ output + workflow_output, status, summary ]
      end
    end
end
