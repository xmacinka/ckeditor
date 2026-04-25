module Ckeditor::ApplicationHelper
  def ckeditor_pagy_nav(pagy)
    return ''.html_safe unless pagy && pagy.pages > 1

    html = +%(<div class="pagination"><ul>)

    if pagy.previous
      html << %(<li class="prev previous_page"><a href="#{pagy.page_url(:previous)}" rel="previous">&lt;</a></li>)
    else
      html << %(<li class="prev previous_page disabled"><span>&lt;</span></li>)
    end

    # Pagy 43 keeps series protected; keep the call local instead of changing Pagy's global visibility.
    pagy.send(:series).each do |item|
      html << case item
              when Integer
                %(<li><a href="#{pagy.page_url(item)}">#{item}</a></li>)
              when String
                %(<li class="active"><span>#{item}</span></li>)
              when :gap
                %(<li class="disabled"><span>&hellip;</span></li>)
              end
    end

    if pagy.next
      html << %(<li class="next next_page"><a href="#{pagy.page_url(:next)}" rel="next">&gt;</a></li>)
    else
      html << %(<li class="next next_page disabled"><span>&gt;</span></li>)
    end

    html << %(</ul></div>)
    html.html_safe
  end

  def assets_pipeline_enabled?
    if Gem::Version.new(::Rails.version.to_s) >= Gem::Version.new('4.0.0')
      defined?(Sprockets::Rails)
    elsif Gem::Version.new(::Rails.version.to_s) >= Gem::Version.new('3.0.0')
      Rails.application.config.assets.enabled
    else
      false
    end
  end
end