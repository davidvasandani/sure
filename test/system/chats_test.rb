require "application_system_test_case"

class ChatsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper
  setup do
    @user = users(:family_admin)
    login_as(@user)
  end

  test "credit error survives reload and manual retries without exposing diagnostics" do
    with_env_overrides OPENAI_ACCESS_TOKEN: "test-token", AI_DEBUG_MODE: "true" do
      chat = chats(:two)
      chat.update!(user: @user, title: "Synthetic credit recovery", error: nil)
      question = messages(:chat2_user)
      question.update!(content: "Synthetic saved question")
      provider = Provider::Openai.new("test-token")
      provider.stubs(:supports_responses_endpoint?).returns(true)
      provider.stubs(:log_langfuse_generation)
      Assistant::Builtin.any_instance.stubs(:get_model_provider).with(question.ai_model).returns(provider)
      canary = "sk-synthetic-browser-canary"

      visit chat_path(chat)
      assert_selector "turbo-cable-stream-source[connected]", visible: :all
      chat.ask_assistant_later(question)
      assert_text I18n.t("chats.thinking")

      2.times do |attempt|
        if attempt.positive?
          within all("##{chat.error_target}").last do
            click_button I18n.t("chats.error.retry")
          end
          page.refresh
          assert_no_selector "##{chat.error_target}"
          assert_text I18n.t("chats.thinking")
        end
        provider.send(:client).responses.expects(:create).with do |parameters:|
          parameters[:stream].call("type" => "response.output_text.delta", "delta" => "Synthetic partial answer")
          parameters[:stream].call("type" => "error", "error" => { "code" => "credit_balance_exhausted", "message" => canary })
          true
        end.returns(nil)

        perform_enqueued_jobs(only: AssistantResponseJob)

        assert_text I18n.t("chat.errors.openai_credits_exhausted")
        assert_no_text canary
        page.refresh
        assert_selector "##{chat.error_target}", text: I18n.t("chat.errors.openai_credits_exhausted")
        assert_text "Synthetic partial answer"
        assert_no_text canary
      end

      evidence = Rails.root.join("specs/vk/dbc7/evidence/chat-credit-error.png")
      FileUtils.mkdir_p(evidence.dirname)
      page.save_screenshot(evidence)

      provider.send(:client).responses.expects(:create).with do |parameters:|
        assert_equal question.ai_model, parameters[:model]
        parameters[:stream].call("type" => "response.output_text.delta", "delta" => "Synthetic recovered answer")
        parameters[:stream].call("type" => "response.completed", "response" => {
          "id" => "synthetic-response", "model" => question.ai_model,
          "output" => [ { "type" => "message", "id" => "synthetic-message", "content" => [ { "text" => "Synthetic recovered answer" } ] } ]
        })
        true
      end.returns(nil)
      within all("##{chat.error_target}").last do
        click_button I18n.t("chats.error.retry")
      end
      page.refresh
      assert_no_selector "##{chat.error_target}"
      assert_text I18n.t("chats.thinking")
      perform_enqueued_jobs(only: AssistantResponseJob)

      assert_text "Synthetic recovered answer"
      page.refresh
      assert_text "Synthetic recovered answer"
      assert_no_selector "##{chat.error_target}"
      assert_nil chat.reload.error
      assert_equal [ question.id ], chat.messages.where(type: "UserMessage").pluck(:id)
      assert_equal question.ai_model, chat.messages.where(type: "AssistantMessage", status: :complete).sole.ai_model
    end
  end

  test "sidebar shows consent if ai is disabled for user" do
    @user.update!(ai_enabled: false)

    visit root_path

    within "#chat-container" do
      assert_selector "h3", text: "Enable AI Chats"
    end
  end

  # Regression test: the mobile bottom-nav "Assistant" item links straight to
  # `/chats`, which has no sidebar to gate. Before this fix that page rendered
  # the compose form unconditionally, letting a user without AI consent send
  # one message (via the unguarded ChatsController#create) before every
  # follow-up message silently 403'd.
  test "chats page shows consent instead of compose form when ai is disabled" do
    @user.update!(ai_enabled: false)
    @user.chats.destroy_all

    visit chats_path

    assert_selector "h3", text: "Enable AI Chats"
    assert_no_selector "textarea[name='chat[content]']"
    assert_no_selector "[data-action='chat#submitSampleQuestion']"
  end

  test "sidebar shows index when enabled and chats are empty" do
    with_env_overrides OPENAI_ACCESS_TOKEN: "test-token" do
      @user.update!(ai_enabled: true)
      @user.chats.destroy_all

      visit root_url

      within "#chat-container" do
        assert_selector "h1", text: "Chats"
      end
    end
  end

  test "the message box shows three lines before it scrolls" do
    with_env_overrides OPENAI_ACCESS_TOKEN: "test-token" do
      chat = @user.chats.first
      @user.update!(ai_enabled: true, last_viewed_chat: chat)

      visit root_url

      within "#chat-container" do
        input = find("#chat-form textarea")
        input.send_keys("One")
        one_line = input.evaluate_script("this.clientHeight")
        input.send_keys([ :shift, :enter ], "Two", [ :shift, :enter ], "Three")
        assert_equal "hidden", input.evaluate_script("getComputedStyle(this).overflowY")
        assert_equal input.evaluate_script("this.scrollHeight"), input.evaluate_script("this.clientHeight")

        three_lines = input.evaluate_script("this.clientHeight")
        assert_operator three_lines, :>, one_line, "the box grows with its lines rather than starting at the cap"
        input.send_keys([ :shift, :enter ], "Four")
        assert_equal "auto", input.evaluate_script("getComputedStyle(this).overflowY")
        assert_equal three_lines, input.evaluate_script("this.clientHeight")
        assert_operator input.evaluate_script("this.scrollHeight"), :>, input.evaluate_script("this.clientHeight")
      end
    end
  end

  test "the message box sizes its three lines from its own line height" do
    with_env_overrides OPENAI_ACCESS_TOKEN: "test-token" do
      chat = @user.chats.first
      @user.update!(ai_enabled: true, last_viewed_chat: chat)

      visit root_url

      within "#chat-container" do
        input = find("#chat-form textarea")
        input.execute_script("this.style.lineHeight = '30px'")
        input.send_keys("One")
        one_line = input.evaluate_script("this.clientHeight")
        input.send_keys([ :shift, :enter ], "Two", [ :shift, :enter ], "Three")
        assert_equal "hidden", input.evaluate_script("getComputedStyle(this).overflowY")
        assert_equal input.evaluate_script("this.scrollHeight"), input.evaluate_script("this.clientHeight")

        three_lines = input.evaluate_script("this.clientHeight")
        assert_operator three_lines, :>, one_line
        input.send_keys([ :shift, :enter ], "Four")
        assert_equal three_lines, input.evaluate_script("this.clientHeight")
        assert_operator input.evaluate_script("this.scrollHeight"), :>, input.evaluate_script("this.clientHeight")
      end
    end
  end

  test "the message box counts its own padding toward the three-line height" do
    with_env_overrides OPENAI_ACCESS_TOKEN: "test-token" do
      chat = @user.chats.first
      @user.update!(ai_enabled: true, last_viewed_chat: chat)

      visit root_url

      within "#chat-container" do
        input = find("#chat-form textarea")
        input.execute_script("this.style.paddingTop = '20px'; this.style.paddingBottom = '20px'")
        input.send_keys("One", [ :shift, :enter ], "Two", [ :shift, :enter ], "Three")
        assert_equal "hidden", input.evaluate_script("getComputedStyle(this).overflowY")
        assert_equal input.evaluate_script("this.scrollHeight"), input.evaluate_script("this.clientHeight")

        three_lines = input.evaluate_script("this.clientHeight")
        input.send_keys([ :shift, :enter ], "Four")
        assert_equal three_lines, input.evaluate_script("this.clientHeight")
        assert_operator input.evaluate_script("this.scrollHeight"), :>, input.evaluate_script("this.clientHeight")
      end
    end
  end

  test "sidebar shows last viewed chat" do
    with_env_overrides OPENAI_ACCESS_TOKEN: "test-token" do
      chat = @user.chats.first
      @user.update!(ai_enabled: true, last_viewed_chat: chat)

      visit root_url

      within "#chat-container" do
        assert_selector "h1", text: chat.title
      end
    end
  end

  test "create chat and navigate chats sidebar" do
    with_env_overrides OPENAI_ACCESS_TOKEN: "test-token" do
      @user.chats.destroy_all

      visit root_url

      Chat.any_instance.expects(:ask_assistant_later).once

      within "#chat-form" do
        fill_in "chat[content]", with: "Can you help with my finances?"
        find("button[type='submit']").click
      end

      assert_text "Can you help with my finances?"

      find("#chat-nav-back").click

      assert_selector "h1", text: "Chats"

      click_on @user.chats.reload.first.title

      assert_text "Can you help with my finances?"
    end
  end

  %w[gpt-6-sol gpt-6.1-sol].each do |model|
    test "create chat with an opted-in #{model} model" do
      with_env_overrides(
        OPENAI_ACCESS_TOKEN: "test-token",
        OPENAI_MODEL: model,
        OPENAI_URI_BASE: nil,
        ASSISTANT_TYPE: "builtin"
      ) do
        Setting.stubs(:openai_uri_base).returns(nil)
        @user.update!(ai_enabled: true)
        @user.chats.destroy_all

        visit root_url
        Chat.any_instance.expects(:ask_assistant_later).once

        within "#chat-form" do
          fill_in "chat[content]", with: "Help me understand my spending"
          find("button[type='submit']").click
        end

        assert_text "Help me understand my spending"
        chat = @user.chats.reload.first
        assert_equal model, chat.messages.where(type: "UserMessage").first.ai_model
        assert_instance_of Assistant::Builtin, Assistant.for_chat(chat)
      end
    end
  end
end
