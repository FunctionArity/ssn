class ServiceMailer < ApplicationMailer
  helper :application

  def mention
    @service = params[:service]
    @author = params[:author]
    @comment = comment_for_email(@service.comments)

    mail to: params[:user].email, subject: t(".subject", full_name: @service.full_name)
  end

  private

  # Links within the app, like the mentions, are relative and wouldn't work in an email, so they become plain bold text.
  def comment_for_email(comments)
    fragment = Nokogiri::HTML5.fragment(comments.to_s)
    fragment.css("a[href^='/']").each do |link|
      link.name = "strong"
      link.remove_attribute("href")
    end
    fragment.to_html
  end
end
