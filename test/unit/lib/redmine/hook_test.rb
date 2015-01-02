#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../../test_helper', __FILE__)

class Redmine::Hook::ManagerTest < ActionView::TestCase
  fixtures :all

  # Some hooks that are manually registered in these tests
  class TestHook < Redmine::Hook::ViewListener; end

  class TestHook1 < TestHook
    def view_layouts_base_html_head(context)
      'Test hook 1 listener.'
    end
  end

  class TestHook2 < TestHook
    def view_layouts_base_html_head(context)
      'Test hook 2 listener.'
    end
  end

  class TestHook3 < TestHook
    def view_layouts_base_html_head(context)
      "Context keys: #{context.keys.collect(&:to_s).sort.join(', ')}."
    end
  end

  class TestLinkToHook < TestHook
    def view_layouts_base_html_head(context)
      link_to('Issues', :controller => 'issues')
    end
  end

  class TestHookHelperController < ActionController::Base
    include Redmine::Hook::Helper
  end

  class TestHookHelperView < ActionView::Base
    include Redmine::Hook::Helper
  end

  Redmine::Hook.clear_listeners

  def setup
    super
    @hook_module = Redmine::Hook
  end

  def teardown
    super
    @hook_module.clear_listeners
  end

  def test_clear_listeners
    assert_equal 0, @hook_module.hook_listeners(:view_layouts_base_html_head).size
    @hook_module.add_listener(TestHook1)
    @hook_module.add_listener(TestHook2)
    assert_equal 2, @hook_module.hook_listeners(:view_layouts_base_html_head).size

    @hook_module.clear_listeners
    assert_equal 0, @hook_module.hook_listeners(:view_layouts_base_html_head).size
  end

  def test_add_listener
    assert_equal 0, @hook_module.hook_listeners(:view_layouts_base_html_head).size
    @hook_module.add_listener(TestHook1)
    assert_equal 1, @hook_module.hook_listeners(:view_layouts_base_html_head).size
  end

  def test_call_hook
    @hook_module.add_listener(TestHook1)
    assert_equal ['Test hook 1 listener.'], hook_helper.call_hook(:view_layouts_base_html_head)
  end

  def test_call_hook_with_context
    @hook_module.add_listener(TestHook3)
    assert_equal ['Context keys: bar, controller, foo, hook_caller, project, request.'],
                 hook_helper.call_hook(:view_layouts_base_html_head, :foo => 1, :bar => 'a')
  end

  def test_call_hook_with_multiple_listeners
    @hook_module.add_listener(TestHook1)
    @hook_module.add_listener(TestHook2)
    assert_equal ['Test hook 1 listener.', 'Test hook 2 listener.'], hook_helper.call_hook(:view_layouts_base_html_head)
  end

  # Context: Redmine::Hook::Helper.call_hook default_url
  def test_call_hook_default_url_options
    @hook_module.add_listener(TestLinkToHook)

    assert_equal ['<a href="/issues">Issues</a>'], hook_helper.call_hook(:view_layouts_base_html_head)
  end

  # Context: Redmine::Hook::Helper.call_hook
  def test_call_hook_with_project_added_to_context
    @hook_module.add_listener(TestHook3)
    assert_match /project/i, hook_helper.call_hook(:view_layouts_base_html_head)[0]
  end

  def test_call_hook_from_controller_with_controller_added_to_context
    @hook_module.add_listener(TestHook3)
    assert_match /controller/i, hook_helper.call_hook(:view_layouts_base_html_head)[0]
  end

  def test_call_hook_from_controller_with_request_added_to_context
    @hook_module.add_listener(TestHook3)
    assert_match /request/i, hook_helper.call_hook(:view_layouts_base_html_head)[0]
  end

  def test_call_hook_from_view_with_project_added_to_context
    @hook_module.add_listener(TestHook3)
    assert_match /project/i, view_hook_helper.call_hook(:view_layouts_base_html_head)
  end

  def test_call_hook_from_view_with_controller_added_to_context
    @hook_module.add_listener(TestHook3)
    assert_match /controller/i, view_hook_helper.call_hook(:view_layouts_base_html_head)
  end

  def test_call_hook_from_view_with_request_added_to_context
    @hook_module.add_listener(TestHook3)
    assert_match /request/i, view_hook_helper.call_hook(:view_layouts_base_html_head)
  end

  def test_call_hook_from_view_should_join_responses_with_a_space
    @hook_module.add_listener(TestHook1)
    @hook_module.add_listener(TestHook2)
    assert_equal 'Test hook 1 listener. Test hook 2 listener.',
                 view_hook_helper.call_hook(:view_layouts_base_html_head)
  end

  def test_call_hook_should_not_change_the_default_url_for_email_notifications
    user = User.find(1)
    issue = WorkPackage.find(1)

    ActionMailer::Base.deliveries.clear
    UserMailer.work_package_added(user, issue).deliver
    mail = ActionMailer::Base.deliveries.last

    @hook_module.add_listener(TestLinkToHook)
    hook_helper.call_hook(:view_layouts_base_html_head)

    ActionMailer::Base.deliveries.clear
    UserMailer.work_package_added(user, issue).deliver
    mail2 = ActionMailer::Base.deliveries.last

    assert_equal mail.text_part.body.encoded, mail2.text_part.body.encoded
  end

  def hook_helper
    @hook_helper ||= TestHookHelperController.new
  end

  def view_hook_helper
    @view_hook_helper ||= TestHookHelperView.new(Rails.root.to_s + '/app/views')
  end
end
