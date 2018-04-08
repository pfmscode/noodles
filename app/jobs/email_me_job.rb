class EmailMeJob < ApplicationJob
  include TextHelper

  def perform(props)
    return if Rails.env.test?
    Aws::SES::Client.new.send_email(destination: {
                                      to_addresses: [
                                        'lachlan@getnoodl.es'
                                      ]
                                    },
                                    message: {
                                      body: {
                                        html: {
                                          charset: 'UTF-8',
                                          data: markdown(props[:body])
                                        },
                                        text: {
                                          charset: 'UTF-8',
                                          data: props[:body]
                                        }
                                      },
                                      subject: {
                                        charset: 'UTF-8',
                                        data: props[:subject]
                                      }
                                    },
                                    source: "Noodles <#{Rails.env}@getnoodl.es>")
  end
end