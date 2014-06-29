#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

require 'spec_helper'

describe ::Query::Results, :type => :model do
  let(:query) { FactoryGirl.build :query }
  let(:query_results) do
    ::Query::Results.new query, include: [:assigned_to, :type, :priority, :category, :fixed_version],
                                order: "work_packages.root_id DESC, work_packages.lft ASC"
  end

  describe '#work_package_count_by_group' do
    context 'when grouping by responsible' do
      before { query.group_by = 'responsible' }

      it 'should produce a valid SQL statement' do
        expect { query_results.work_package_count_by_group }.not_to raise_error
      end
    end
  end

  describe '#work_packages' do
    let!(:project_1) { FactoryGirl.create :project }
    let!(:project_2) { FactoryGirl.create :project }
    let!(:role_pm) { FactoryGirl.create(:role,
                                        name: 'Manager',
                                        permissions: [
                                                       :view_work_packages,
                                                       :edit_work_packages,
                                                       :create_work_packages,
                                                       :delete_work_packages
                                        ])}
    let!(:role_dev) { FactoryGirl.create(:role,
                                         name: 'Developer',
                                         permissions: [:view_work_packages])}
    let!(:user_1) { FactoryGirl.create(:user,
                                       member_in_project: project_1,
                                       member_through_role: [role_dev, role_pm]) }
    let!(:member) { FactoryGirl.create(:member,
                                       project: project_2,
                                       principal: user_1,
                                       roles: [role_pm]) }
    let!(:user_2) { FactoryGirl.create(:user,
                                       member_in_project: project_2,
                                       member_through_role: role_dev) }

    let!(:wp_p1) { (1..3).collect { FactoryGirl.create(:work_package,
                                                       project: project_1,
                                                       assigned_to_id: user_1.id) } }
    let!(:wp_p2) { FactoryGirl.create(:work_package,
                                      project: project_2,
                                      assigned_to_id: user_2.id) }
    let!(:wp2_p2) { FactoryGirl.create(:work_package,
                                       project: project_2,
                                       assigned_to_id: user_1.id) }

    before do
      User.stub(:current).and_return(user_2)
      project_2.descendants.stub(:active).and_return([])

      query.add_filter("assigned_to_role", "=", ["#{role_dev.id}"])
    end

    context 'when a project is set' do
      before do
        query.stub(:project).and_return(project_2)
        query.stub(:project_id).and_return(project_2.id)
      end

      it 'should display only wp for selected project and selected role' do
        expect(query_results.work_packages).to match_array([wp_p2])
      end
    end

    context 'when no project is set' do
      before do
        query.stub(:project_id).and_return(false)
        query.stub(:project).and_return(false)
      end

      it 'should display all wp from projects where User.current has access' do
        expect(query_results.work_packages).to match_array([wp_p2, wp2_p2])
      end
    end
  end
end
