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

class Attachments::CreateService
  include Attachments::TouchContainer

  attr_reader :container, :author

  def initialize(container, author:)
    @container = container
    @author = author
  end

  ##
  # Adds and saves the uploaded file as attachment of the given container.
  # In case the container supports it, a journal will be written.
  #
  # An ActiveRecord::RecordInvalid error is raised if any record can't be saved.
  def call(uploaded_file:, description:)
    create_attachment(uploaded_file, description)
      .tap(&method(:created_event))
  end

  private

  def create_attachment(uploaded_file, description)
    if container.nil?
      save_attachment(uploaded_file, description)
    elsif container.class.journaled?
      create_journalized(uploaded_file, description)
    else
      create_unjournalized(uploaded_file, description)
    end
  end

  def create_journalized(uploaded_file, description)
    OpenProject::Mutex.with_advisory_lock_transaction(container) do
      save_attachment(uploaded_file, description).tap do
        # Get the latest attachments to ensure having them all for journalization.
        # We just created an attachment and a different worker might have added attachments
        # in the meantime, e.g when bulk uploading.
        container.attachments.reload

        touch(container)
      end
    end
  end

  def create_unjournalized(uploaded_file, description)
    save_attachment(uploaded_file, description).tap do
      touch(container)
    end
  end

  def save_attachment(uploaded_file, description)
    attachment = Attachment.new(file: uploaded_file,
                                container: container,
                                description: description,
                                author: author)

    attachment.save!
    attachment
  end

  def build_attachment(uploaded_file, description)
    container.attachments.build(file: uploaded_file,
                                description: description,
                                content_type: uploaded_file.content_type,
                                author: author)
  end

  def created_event(attachment)
    OpenProject::Notifications.send(
      OpenProject::Events::ATTACHMENT_CREATED,
      attachment: attachment
    )
  end
end
