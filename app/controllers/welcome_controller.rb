class WelcomeController < ApplicationController
  helper :questions
  tabs :default => :welcome

  def index
    @active_subtab = params.fetch(:tab, "activity")

    order = "activity_at desc"
    case @active_subtab
      when "activity"
        order = "activity_at desc"
      when "hot"
        order = "hotness desc"
    end

    @langs_conds = scoped_conditions[:language][:$in]
    add_feeds_url(url_for(:format => "atom", :languages => @langs_conds),
                                                    t("feeds.questions"))

    @questions = Question.paginate({:per_page => 15,
                                   :page => params[:page] || 1,
                                   :fields => (Question.keys.keys - ["_keywords", "watchers"]),
                                   :order => order}.merge(
                                   scoped_conditions({:banned => false})))
  end

  def feedback
  end

  def send_feedback
    if params[:result].blank? ||
       (params[:result].to_i != (params[:n1].to_i * params[:n2].to_i))
      flash[:error] = I18n.t("welcome.feedback.captcha_error")
      flash[:error] += ". Domo arigato, Mr. Roboto. "
      redirect_to feedback_path(:feedback => params[:feedback])
    else
      Notifier.deliver_new_feedback(current_user, params[:feedback][:title],
                                                  params[:feedback][:description],
                                                  params[:feedback][:email],
                                                  request.remote_ip)
      redirect_to root_path
    end
  end

  def facts
  end

end

