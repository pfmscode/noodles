module NavHelper
  def nav_active_class(nav)
    nav_active?(nav) ? 'px1 bold' : 'px1'
  end

  def nav_active?(nav)
    @navs ||= []
    @navs.include?(nav.to_sym)
  end

  def activate_nav!(nav)
    @navs ||= []
    @navs.push(nav.to_sym)
  end
end
