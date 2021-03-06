require 'test_helper'

class SvgHelperTest < ActionView::TestCase
  include SvgHelper

  test 'inline svg' do
    assert_not_nil inline_svg('cook.svg')
  end

  test 'inline svg path' do
    assert_not_nil inline_svg_path('cook.svg')
  end
end
