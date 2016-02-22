class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@twitchdeck.io'
  layout 'mailer'
end
