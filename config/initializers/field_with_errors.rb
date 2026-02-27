ActionView::Base.field_error_proc = Proc.new do |html_tag, _instance|
  if html_tag =~ /class="/
    html_tag.gsub(/class="/, 'class="has_error ').html_safe
  else
    html_tag.gsub(/\A<(\S+)/, '<\1 class="has_error"').html_safe
  end
end
