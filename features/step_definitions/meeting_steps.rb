#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2011-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Given /^there is (\d+) [Mm]eetings? in project "(.+)" created by "(.+)" with:$/ do |count,project,user,table|
  count.to_i.times do
    m = FactoryGirl.build(:meeting)
    m.project = Project.find_by_name(project)
    m.author  = User.find_by_login(user)
    send_table_to_object(m, table)
  end
end

Given /^there is (\d+) [Mm]eetings? in project "(.+)" that start (.*) days? from now with:$/ do |count,project,time,table|
  count.to_i.times do
    m = FactoryGirl.build(:meeting, :start_time => Time.now + time.to_i.days)
    m.project = Project.find_by_name(project)
    send_table_to_object(m, table)
  end
end

Given /^the [Mm]eeting "(.+)" has 1 agenda with:$/ do |meeting,table|
  m = Meeting.find_by_title(meeting)
  ma = MeetingAgenda.find_by_meeting_id(m.id) || FactoryGirl.build(:meeting_agenda, :meeting => m)
  send_table_to_object(ma, table)
end

Given /^the [Mm]eeting "(.+)" has 1 agenda$/ do |meeting|
  m = Meeting.find_by_title(meeting)
  m.agenda ||= FactoryGirl.build(:meeting_agenda)
  m.save!
end

Given /^the [Mm]eeting "(.+)" has minutes with:$/ do |meeting,table|
  m = Meeting.find_by_title(meeting)
  mm = MeetingMinutes.find_by_meeting_id(m.id) || FactoryGirl.build(:meeting_minutes, :meeting => m)
  send_table_to_object(mm, table)
end

Given /^"(.+)" is invited to the [Mm]eeting "(.+)"$/ do |user,meeting|
  m = Meeting.find_by_title(meeting)
  p = m.participants.detect{|p| p.user_id = User.find_by_login(user).id} || FactoryGirl.build(:meeting_participant, :meeting => m)
  p.invited = true
  p.save
end

Given /^"(.+)" attended the [Mm]eeting "(.+)"$/ do |user,meeting|
  m = Meeting.find_by_title(meeting)
  p = m.participants.detect{|p| p.user_id = User.find_by_login(user).id} || FactoryGirl.build(:meeting_participant, :meeting => m)
  p.attended = true
  p.save
end

When /the agenda of the meeting "(.+)" changes meanwhile/ do |meeting|
  m = Meeting.find_by_title(meeting)
  m.agenda.text = "oder oder?"
  m.agenda.save!
end

Then /^the minutes should contain the following text:$/ do |table|
  step %Q{I should see "#{table.raw.first.first}" within "#meeting_minutes-text"}
end
