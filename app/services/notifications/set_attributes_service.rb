#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Notifications
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_default_attributes(params)
      super

      set_default_subject unless model.subject
      set_default_project unless model.project
    end

    def set_default_subject
      # TODO: Work package journal specific.
      # Extract into strategy per event resource
      journable = model.resource

      class_name = journable.class.name.underscore

      model.subject = I18n.t("notifications.#{class_name.pluralize}.subject.#{model.reason}",
                             **{ class_name.to_sym => journable.to_s })
    end

    ##
    # Try to determine the project context from the journal (if any)
    # or the resource if it has a project set
    def set_default_project
      model.project = model.journal&.project || model.resource.try(:project)
    end
  end
end
