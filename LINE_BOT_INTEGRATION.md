# Building a LINE Chatbot with AI-Powered Conversation Analysis

A comprehensive guide for junior developers on integrating LINE Messaging API with Ruby on Rails and Claude AI.

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Part 1: Setting Up LINE Developer Account](#part-1-setting-up-line-developer-account)
4. [Part 2: Rails Application Setup](#part-2-rails-application-setup)
5. [Part 3: Building the Webhook Controller](#part-3-building-the-webhook-controller)
6. [Part 4: Storing Messages for Context](#part-4-storing-messages-for-context)
7. [Part 5: AI-Powered Conversation Analysis](#part-5-ai-powered-conversation-analysis)
8. [Part 6: Linking LINE Groups to Your App](#part-6-linking-line-groups-to-your-app)
9. [Part 7: Local Development with ngrok](#part-7-local-development-with-ngrok)
10. [Part 8: Deploying to Production](#part-8-deploying-to-production)
11. [Key Concepts & Lessons Learned](#key-concepts--lessons-learned)

---

## Introduction

### What We're Building

A LINE chatbot that:
- Listens to group conversations silently
- Responds when triggered by a keyword ("kokai")
- Uses AI (Claude) to analyze conversations and extract decisions
- Creates events and tasks in our app based on what was discussed

### Why This Architecture?

Most chatbots respond to every message, which can be annoying in group chats. Our approach:
1. **Passive listening** - Store all messages but stay quiet
2. **Trigger-based activation** - Only respond when explicitly called
3. **Context-aware AI** - Analyze the full conversation, not just one message
4. **Smart extraction** - Understand the *final* decisions after back-and-forth discussion

---

## Prerequisites

- Ruby on Rails application
- PostgreSQL database
- Heroku account (for deployment)
- LINE Developer account
- Anthropic API key (for Claude AI)

---

## Part 1: Setting Up LINE Developer Account

### Step 1: Create a LINE Developer Account

1. Go to [LINE Developers Console](https://developers.line.biz/)
2. Log in with your LINE account
3. Create a new Provider (e.g., "My Company")

### Step 2: Create a Messaging API Channel

1. Click "Create a new channel"
2. Select "Messaging API"
3. Fill in the required information:
   - Channel name: Your bot's name
   - Channel description: What your bot does
   - Category: Choose appropriate category
   - Subcategory: Choose appropriate subcategory

### Step 3: Get Your Credentials

After creating the channel, you'll need two things:

1. **Channel Secret** - Found in "Basic settings" tab
2. **Channel Access Token** - Found in "Messaging API" tab (click "Issue" if not generated)

Save these securely - you'll need them later!

### Step 4: Configure Webhook Settings

In the "Messaging API" tab:
1. Set Webhook URL (we'll set this after deployment)
2. Enable "Use webhook"
3. Disable "Auto-reply messages" (we'll handle replies ourselves)
4. Disable "Greeting messages" (optional)

---

## Part 2: Rails Application Setup

### Step 1: Add Required Gems

```ruby
# Gemfile
gem 'line-bot-api'  # Official LINE SDK (optional, we use raw HTTP)
gem 'anthropic'     # Claude AI client
```

Run:
```bash
bundle install
```

### Step 2: Set Environment Variables

```bash
# .env (for local development)
LINE_CHANNEL_SECRET=your_channel_secret_here
LINE_CHANNEL_ACCESS_TOKEN=your_channel_access_token_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

For Heroku:
```bash
heroku config:set LINE_CHANNEL_SECRET=xxx
heroku config:set LINE_CHANNEL_ACCESS_TOKEN=xxx
heroku config:set ANTHROPIC_API_KEY=xxx
```

### Step 3: Add Route for Webhook

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :webhooks do
    post 'line', to: 'line#receive'
  end
end
```

This creates the endpoint `POST /webhooks/line` that LINE will call.

---

## Part 3: Building the Webhook Controller

### Understanding Webhooks

A webhook is like a reverse API call:
- Normal API: Your app calls someone else's server
- Webhook: Someone else's server calls your app

When a user sends a message in LINE, LINE's servers send an HTTP POST request to your webhook URL with the message data.

### The Basic Controller Structure

```ruby
# app/controllers/webhooks/line_controller.rb
module Webhooks
  class LineController < ApplicationController
    # Skip Rails security checks - LINE can't send CSRF tokens
    skip_before_action :verify_authenticity_token

    # Skip authentication - this is a public endpoint for LINE
    skip_before_action :authenticate_user!

    # Skip authorization if using Pundit
    skip_after_action :verify_authorized

    def receive
      body = request.body.read
      signature = request.env['HTTP_X_LINE_SIGNATURE']

      # IMPORTANT: Always verify the request is really from LINE
      unless valid_signature?(body, signature)
        Rails.logger.warn "LINE webhook: Invalid signature"
        head :bad_request
        return
      end

      # Parse and handle each event
      events = JSON.parse(body)['events'] || []
      events.each do |event|
        handle_event(event)
      end

      head :ok
    end

    private

    def valid_signature?(body, signature)
      return false if signature.blank?

      # LINE signs requests using HMAC-SHA256
      hash = OpenSSL::HMAC.digest(
        OpenSSL::Digest::SHA256.new,
        ENV['LINE_CHANNEL_SECRET'],
        body
      )
      Base64.strict_encode64(hash) == signature
    end

    def handle_event(event)
      case event['type']
      when 'message'
        handle_message(event)
      when 'join'
        handle_join(event)
      when 'leave'
        handle_leave(event)
      end
    rescue StandardError => e
      Rails.logger.error "LINE webhook error: #{e.message}"
    end
  end
end
```

### Why Signature Verification Matters

Anyone could send POST requests to your webhook URL pretending to be LINE. The signature verification ensures:
1. The request really came from LINE
2. The request body wasn't tampered with

LINE creates a signature using your Channel Secret (which only you and LINE know). If someone doesn't have your secret, they can't create a valid signature.

### Handling Different Event Types

LINE sends different event types:

```ruby
def handle_event(event)
  case event['type']
  when 'message'
    # User sent a message
    handle_message(event)
  when 'join'
    # Bot was added to a group
    handle_join(event)
  when 'leave'
    # Bot was removed from a group
    handle_leave(event)
  when 'follow'
    # User added the bot as a friend
    handle_follow(event)
  when 'unfollow'
    # User blocked the bot
    handle_unfollow(event)
  end
end
```

### Processing Messages

```ruby
def handle_message(event)
  # Only handle text messages (not images, stickers, etc.)
  message_type = event.dig('message', 'type')
  return unless message_type == 'text'

  # Extract useful information from the event
  text = event.dig('message', 'text')
  source_type = event.dig('source', 'type')  # 'user', 'group', or 'room'
  user_id = event.dig('source', 'userId')
  group_id = event.dig('source', 'groupId')
  reply_token = event['replyToken']
  message_id = event.dig('message', 'id')
  timestamp = event['timestamp']

  Rails.logger.info "LINE message from #{source_type}: #{text}"

  # Your logic here...
end
```

### Sending Replies

LINE uses a "reply token" system. Each incoming message includes a token you can use to reply (valid for ~30 seconds):

```ruby
def send_reply(reply_token, text)
  return if reply_token.blank?

  uri = URI.parse('https://api.line.me/v2/bot/message/reply')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)
  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{ENV['LINE_CHANNEL_ACCESS_TOKEN']}"
  request.body = {
    replyToken: reply_token,
    messages: [{ type: 'text', text: text }]
  }.to_json

  response = http.request(request)
  Rails.logger.info "LINE reply response: #{response.code}"
rescue StandardError => e
  Rails.logger.error "LINE reply error: #{e.message}"
end
```

---

## Part 4: Storing Messages for Context

### Why Store Messages?

To analyze a conversation, we need to remember what was said. We store messages so the AI can see the full context.

### Create the Migration

```bash
rails generate model LineMessage \
  line_group_id:string \
  line_user_id:string \
  display_name:string \
  content:text \
  message_id:string \
  sent_at:datetime \
  processed_at:datetime
```

```ruby
# db/migrate/xxx_create_line_messages.rb
class CreateLineMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :line_messages do |t|
      t.string :line_group_id, null: false
      t.string :line_user_id
      t.string :display_name
      t.text :content, null: false
      t.string :message_id
      t.datetime :sent_at, null: false
      t.datetime :processed_at  # Track which messages we've analyzed

      t.timestamps
    end

    add_index :line_messages, :line_group_id
    add_index :line_messages, [:line_group_id, :sent_at]
    add_index :line_messages, :message_id, unique: true
  end
end
```

### The Model

```ruby
# app/models/line_message.rb
class LineMessage < ApplicationRecord
  validates :line_group_id, presence: true
  validates :content, presence: true
  validates :sent_at, presence: true
  validates :message_id, uniqueness: true, allow_nil: true

  scope :for_group, ->(group_id) { where(line_group_id: group_id) }
  scope :unprocessed, -> { where(processed_at: nil) }

  # Get messages that haven't been analyzed yet
  def self.unprocessed_for_group(group_id, limit: 50)
    for_group(group_id)
      .unprocessed
      .order(sent_at: :asc)
      .limit(limit)
  end

  # Mark messages as processed so we don't analyze them again
  def self.mark_as_processed(group_id)
    for_group(group_id)
      .unprocessed
      .update_all(processed_at: Time.current)
  end

  # Format messages for the AI to read
  def self.format_conversation(messages)
    messages.map do |msg|
      name = msg.display_name || "Someone"
      "#{name}: #{msg.content}"
    end.join("\n")
  end
end
```

### Storing Messages in the Controller

```ruby
def handle_message(event)
  # ... extract text, user_id, group_id, etc.

  # Store the message for conversation context (only for groups)
  if group_id.present?
    store_message(group_id, user_id, text, message_id, timestamp)
  end

  # ... rest of your logic
end

def store_message(group_id, user_id, content, message_id, timestamp)
  # Get display name for the user
  display_name = nil
  if user_id.present? && group_id.present?
    profile = get_group_member_profile(group_id, user_id)
    display_name = profile&.dig('displayName')
  end

  # Convert LINE timestamp (milliseconds) to datetime
  sent_at = timestamp ? Time.at(timestamp / 1000.0) : Time.current

  LineMessage.create(
    line_group_id: group_id,
    line_user_id: user_id,
    display_name: display_name,
    content: content,
    message_id: message_id,
    sent_at: sent_at
  )
rescue StandardError => e
  Rails.logger.error "Failed to store LINE message: #{e.message}"
end
```

### Getting User Profiles in Groups

LINE has different API endpoints for getting user profiles:
- Direct messages: `/v2/bot/profile/{userId}`
- Group chats: `/v2/bot/group/{groupId}/member/{userId}`

```ruby
def get_group_member_profile(group_id, user_id)
  uri = URI.parse("https://api.line.me/v2/bot/group/#{group_id}/member/#{user_id}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri.path)
  request['Authorization'] = "Bearer #{ENV['LINE_CHANNEL_ACCESS_TOKEN']}"

  response = http.request(request)
  return nil unless response.code == '200'

  JSON.parse(response.body)
rescue StandardError => e
  Rails.logger.error "LINE group member profile fetch error: #{e.message}"
  nil
end
```

---

## Part 5: AI-Powered Conversation Analysis

### The Service Class

```ruby
# app/services/line/conversation_analyzer_service.rb
module Line
  class ConversationAnalyzerService
    SYSTEM_PROMPT = <<~PROMPT
      You are analyzing a band group chat conversation to extract the FINAL decisions about events, plans, and tasks.

      Today's date is %{date} (%{day_name}).

      IMPORTANT: "kokai" is NOT a person - it is a trigger word to summon this bot. Ignore any message that just says "kokai" or similar.

      The participants in this conversation are: %{participants}
      Only use names from this list for assigned_to. If someone volunteers for a task, use their name from this list.

      The conversation may have back-and-forth discussion, changes of plans, and cancellations.
      Your job is to identify what was FINALLY agreed upon, ignoring earlier suggestions that were changed.

      Return ONLY valid JSON with this structure:
      {
        "events": [
          {
            "event_type": "rehearsal" | "gig" | "meeting" | "recording" | "other",
            "title": "string or null",
            "date": "YYYY-MM-DD",
            "start_time": "HH:MM (24h) or null",
            "end_time": "HH:MM (24h) or null",
            "location": "string or null",
            "status": "confirmed" | "cancelled" | "tentative"
          }
        ],
        "tasks": [
          {
            "name": "task description",
            "task_type": "rehearsal" | "recording" | "writing" | "booking" | "promotion" | "admin" | "other",
            "deadline": "YYYY-MM-DD or null",
            "assigned_to": "person name from participants list, or null if unassigned"
          }
        ],
        "summary": "Brief 1-2 sentence summary of what was decided"
      }

      Rules:
      - Events are scheduled activities with a specific date/time
      - Tasks are things someone needs to DO (book a venue, write lyrics, etc.)
      - Only include items that were CONFIRMED or agreed upon
      - If someone cancels or changes plans, use the FINAL decision
      - Convert relative dates (tomorrow, next Wednesday) to actual dates
      - Support both English and Japanese
      - For task assignments, look for:
        * Someone volunteering: "I'll do it", "I can handle that"
        * Someone being asked and agreeing: "Can you do X?" followed by "Sure", "OK"
        * The assigned_to MUST be a name from the participants list, or null

      Return empty arrays if nothing was discussed.
    PROMPT

    def initialize(group_id)
      @group_id = group_id
    end

    def analyze
      messages = LineMessage.unprocessed_for_group(@group_id, limit: 50)
      return empty_result if messages.empty?

      conversation = LineMessage.format_conversation(messages)
      return empty_result if conversation.blank?

      # Extract unique participant names from the messages
      participants = messages.map(&:display_name).compact.uniq.reject { |name| name.downcase == 'someone' }

      response = call_claude(conversation, participants)
      result = parse_response(response)

      # Mark messages as processed so they won't be analyzed again
      LineMessage.mark_as_processed(@group_id)

      result
    rescue StandardError => e
      Rails.logger.error "Conversation analysis error: #{e.message}"
      empty_result
    end

    private

    def call_claude(conversation, participants)
      client = Anthropic::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])

      participants_list = participants.any? ? participants.join(', ') : 'Unknown participants'
      prompt = format(
        SYSTEM_PROMPT,
        date: Date.current.strftime('%Y-%m-%d'),
        day_name: Date.current.strftime('%A'),
        participants: participants_list
      )

      response = client.messages.create(
        model: 'claude-3-haiku-20240307',  # Fast and cheap for this use case
        max_tokens: 1000,
        system: prompt,
        messages: [
          { role: 'user', content: "Analyze this conversation and extract the final decisions:\n\n#{conversation}" }
        ]
      )

      response.content.first.text
    end

    def parse_response(response)
      json = JSON.parse(response)
      json.with_indifferent_access
    rescue JSON::ParserError
      # Try to extract JSON from response (AI sometimes adds extra text)
      if response =~ /\{.*\}/m
        JSON.parse(response[/\{.*\}/m]).with_indifferent_access
      else
        empty_result
      end
    end

    def empty_result
      {
        events: [],
        tasks: [],
        summary: "No events, tasks, or plans found in the conversation."
      }.with_indifferent_access
    end
  end
end
```

### Key AI Prompt Design Principles

1. **Be specific about the output format** - Tell the AI exactly what JSON structure you expect
2. **Handle edge cases** - Tell the AI what to do when things are ambiguous
3. **Provide context** - Include today's date so relative dates can be converted
4. **Constrain the AI** - "MUST be a name from the participants list" prevents hallucinations
5. **Support multiple languages** - Our users speak English and Japanese

### Using the Analyzer in the Controller

```ruby
def handle_kokai_trigger(text, user_id, group_id, reply_token)
  # Check if there are any unprocessed messages to analyze
  unprocessed_count = LineMessage.unprocessed_for_group(group_id).count
  if unprocessed_count <= 1  # Only the "kokai" message itself
    send_reply(reply_token, "No new messages to analyze since last time.")
    return
  end

  # Analyze the conversation
  Rails.logger.info "Analyzing #{unprocessed_count} messages for group: #{group_id}"
  result = Line::ConversationAnalyzerService.new(group_id).analyze

  # Process the results and create records in your app...
  # (events, tasks, etc.)

  send_reply(reply_token, result[:summary])
end
```

---

## Part 6: Linking LINE Groups to Your App

### The Problem

When LINE sends a webhook, it only gives you a `groupId` like `C1234567890abcdef`. How do you know which band/team/organization this group belongs to?

### The Solution: Link Codes

1. User generates a unique code in your web app
2. User sends the code to the LINE group: `/link ABC123`
3. Bot associates the LINE group ID with the band

### Create the Connection Model

```ruby
# app/models/line_band_connection.rb
class LineBandConnection < ApplicationRecord
  belongs_to :band
  belongs_to :linked_by, class_name: 'User', optional: true

  validates :link_code, uniqueness: true, allow_nil: true
  validates :line_group_id, uniqueness: true, allow_nil: true

  before_create :generate_link_code

  def linked?
    line_group_id.present? && linked_at.present?
  end

  def link_to_group!(group_id)
    update!(
      line_group_id: group_id,
      linked_at: Time.current,
      active: true
    )
  end

  def self.find_by_link_code(code)
    return nil if code.blank?
    find_by(link_code: code.upcase.strip)
  end

  private

  def generate_link_code
    loop do
      self.link_code = SecureRandom.alphanumeric(8).upcase
      break unless self.class.exists?(link_code: link_code)
    end
  end
end
```

### Handle the Link Command

```ruby
def handle_command(text, user_id, group_id, reply_token)
  parts = text.split(' ', 2)
  command = parts[0].downcase
  args = parts[1]

  case command
  when '/link'
    handle_link_command(args, group_id, reply_token)
  when '/help'
    send_reply(reply_token, help_message)
  # ... other commands
  end
end

def handle_link_command(args, group_id, reply_token)
  # Check if already linked
  existing = LineBandConnection.find_by(line_group_id: group_id, active: true)
  if existing
    send_reply(reply_token, "This group is already linked to #{existing.band.name}!")
    return
  end

  if args.blank?
    send_reply(reply_token, "Usage: /link YOUR_CODE\n\nGet your code from the band settings page.")
    return
  end

  # Find the connection by link code
  connection = LineBandConnection.find_by_link_code(args.strip)

  if connection.nil?
    send_reply(reply_token, "Invalid link code. Please check and try again.")
    return
  end

  if connection.linked?
    send_reply(reply_token, "This code has already been used.")
    return
  end

  # Link the group!
  connection.link_to_group!(group_id)

  send_reply(reply_token, "Successfully linked to #{connection.band.name}!")
end
```

---

## Part 7: Local Development with ngrok

### The Problem

LINE needs to send webhooks to a public URL, but your development machine is behind a router/firewall.

### The Solution: ngrok

ngrok creates a tunnel from a public URL to your local machine.

### Step 1: Install ngrok

```bash
# macOS
brew install ngrok

# Or download from https://ngrok.com/download
```

### Step 2: Start Your Rails Server

```bash
rails server -p 3000
```

### Step 3: Start ngrok

```bash
ngrok http 3000
```

You'll see output like:
```
Forwarding    https://abc123.ngrok.io -> http://localhost:3000
```

### Step 4: Configure LINE

1. Go to LINE Developer Console
2. Set Webhook URL to: `https://abc123.ngrok.io/webhooks/line`
3. Click "Verify" to test the connection

### Important Notes

- ngrok URLs change every time you restart ngrok (unless you have a paid plan)
- You'll need to update the LINE webhook URL each time
- Great for debugging - you can see all requests in the ngrok web interface at `http://localhost:4040`

---

## Part 8: Deploying to Production

### Heroku Deployment

```bash
# Push to Heroku
git push heroku master

# Run migrations
heroku run rails db:migrate

# Set environment variables
heroku config:set LINE_CHANNEL_SECRET=your_secret
heroku config:set LINE_CHANNEL_ACCESS_TOKEN=your_token
heroku config:set ANTHROPIC_API_KEY=your_key
```

### Update LINE Webhook URL

Change the webhook URL in LINE Developer Console to your Heroku URL:
```
https://your-app-name.herokuapp.com/webhooks/line
```

### Monitoring

```bash
# View logs in real-time
heroku logs --tail

# Check for errors
heroku logs --tail | grep -i error
```

---

## Key Concepts & Lessons Learned

### 1. Webhook Security

**Always verify signatures.** Anyone can send POST requests to your webhook URL. The signature proves the request came from LINE.

### 2. Idempotency

Messages might be delivered multiple times. Use the `message_id` to detect duplicates:
```ruby
validates :message_id, uniqueness: true, allow_nil: true
```

### 3. Reply Token Expiration

Reply tokens expire after ~30 seconds. If you need to respond later, use the Push API instead (requires user consent).

### 4. Rate Limits

LINE has rate limits. For high-volume bots, implement queuing with background jobs (Sidekiq/Resque).

### 5. AI Prompt Engineering

- Be explicit about output format
- Provide examples when helpful
- Constrain outputs to prevent hallucinations
- Handle parsing errors gracefully

### 6. The "Quiet Bot" Pattern

Instead of responding to every message:
1. Store messages silently
2. Wait for an explicit trigger
3. Analyze the full context
4. Respond with actionable results

This makes the bot feel like a helpful assistant rather than an annoying interruption.

### 7. Incremental Processing

Mark messages as "processed" after analyzing them:
```ruby
LineMessage.mark_as_processed(@group_id)
```

This prevents analyzing the same messages twice.

### 8. Graceful Degradation

Always have fallbacks:
```ruby
rescue StandardError => e
  Rails.logger.error "Error: #{e.message}"
  empty_result  # Return safe default instead of crashing
end
```

### 9. Different API Endpoints for Groups vs. DMs

LINE uses different endpoints depending on context:
- Profile in DM: `/v2/bot/profile/{userId}`
- Profile in group: `/v2/bot/group/{groupId}/member/{userId}`

### 10. Testing Webhooks Locally

Use ngrok for development, but remember:
- URLs change on restart
- Update LINE webhook URL each time
- Use `http://localhost:4040` to inspect requests

---

## Further Reading

- [LINE Messaging API Documentation](https://developers.line.biz/en/docs/messaging-api/)
- [Anthropic Claude API Documentation](https://docs.anthropic.com/)
- [ngrok Documentation](https://ngrok.com/docs)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)

---

## Questions?

If you're stuck, check:
1. Rails logs: `heroku logs --tail` or your local terminal
2. LINE webhook delivery status in Developer Console
3. ngrok inspector: `http://localhost:4040`

Happy coding!
