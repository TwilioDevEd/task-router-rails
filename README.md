<a  href="https://www.twilio.com">
<img  src="https://static0.twilio.com/marketing/bundles/marketing/img/logos/wordmark-red.svg"  alt="Twilio"  width="250"  />
</a>
 
# Task Router - Rails

![](https://github.com/TwilioDevEd/task-router-rails/actions/workflows/build.yml/badge.svg)

Give your customers specialized product support. Learn how to use TaskRouter to
create a workflow that will redirect users to an appropriate sales agent, based
on the product they select.

## Local Development

This project is built using [Ruby on Rails](http://rubyonrails.org/) Framework for the backend and [NodeJS](https://nodejs.org/en/) to serve the frontend assets.

1. First clone this repository and `cd` into it.

   ```bash
   $ git clone git@github.com:TwilioDevEd/task-router-rails.git
   $ cd task-router-rails
   ```

1. Install the backend dependencies. Be sure to have [SQLite](https://www.sqlite.org/download.html) installed on your system before running this command.

   ```bash
   $ bundle install
   ```

1. Install the frontend dependencies.
   ```bash
   $ npm install
   ```

1. Expose your application to the wider internet using [ngrok](http://ngrok.com).

   This step is important because the application won't work as expected if you run it through
   localhost.

   ```bash
   $ ngrok http 3000
   ```

   Your ngrok URL should look something like this: `http://9a159ccf.ngrok.io`

   You can read [this blog post](https://www.twilio.com/blog/2015/09/6-awesome-reasons-to-use-ngrok-when-testing-webhooks.html)
   for more details on how to use ngrok.

1. Configure Twilio to call your webhooks

   You will also need to configure Twilio to call your application when calls or SMSs are received on your `TWILIO_NUMBER`. Your urls should look something like this:

   ```
   voice: http://9a159ccf.ngrok.io/call/incoming

   sms:   http://9a159ccf.ngrok.io/message/incoming
   ```

   [Learn how to configure a Twilio phone number for Programmable Voice](https://www.twilio.com/docs/voice/quickstart/ruby#configure-your-webhook-url)

   [Learn how to configure a Twilio phone number for Programmable SMS](https://support.twilio.com/hc/en-us/articles/223136047-Configure-a-Twilio-Phone-Number-to-Receive-and-Respond-to-Messages)

1. Copy the sample configuration file and edit it to match your configuration.

   ```bash
   $ cp .env.example .env
   ```

   You can find your `TWILIO_ACCOUNT_SID` and `TWILIO_AUTH_TOKEN` in your
   [Twilio Account Settings](https://www.twilio.com/console/account/settings).
   You will also need a `TWILIO_NUMBER`, which you may find [here](https://www.twilio.com/console/phone-numbers/incoming).

1. Create database and run migrations.

   ```bash
   $ bundle exec rake db:setup
   ```

1. Make sure the tests succeed.

   ```bash
   $ bundle exec rspec
   ```

1. Start the server.

   ```bash
   $ bundle exec rails s
   ```

That's it!

## How to Demo

1. First make sure you have correctly filled all the required environment variables from the `.env.example` file. Bob and Alice's number should be two different numbers where you can receive calls and SMSs.

1. When you run the app, a new workspace will be configured. Once that is done, you are ready to call your [Twilio Number](https://www.twilio.com/console/phone-numbers/incoming) where you'll be asked to select a product using your key pad.

1. Select and option and the phone assigned to the product you selected (Bob or Alice's) will start ringing. You can answer the call and have a conversation.

1. Alternatively, if you don't answer the call within 15 seconds, the call should be redirected to the next worker. If the call isn't answered by the second worker, you should be redirected to voice mail and leave a message. The transcription of that message should be sent to the email you specified in your environment variables.

1. Each time a worker misses a call, their activity is changed to offline. Right after they should receive a notification, via SMS, saying that they missed the call. In order to go back online they can reply with `On`. They can as well reply with `Off` in order to go back to offline status.

1. If both workers' activity changes to `Offline` and you call your Twilio Number again, you should be redirected to voice mail after a few seconds as the workflow timeouts when there are no available workers. Change your workers status with the `On` SMS command to be able to receive calls again.

1. Navigate to `https://<ngrok_subdomain>.ngrok.io` to see a list of the missed calls.

## Meta

* No warranty expressed or implied. Software is as is. Diggity.
* [MIT License](LICENSE)
* Lovingly crafted by Twilio Developer Education.
