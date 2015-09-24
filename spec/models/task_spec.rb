require 'rails_helper'

describe Task do
  it { should have_many(:volunteers).class_name(Volunteer) }
  it { should have_many(:organizers).class_name(Volunteer) }
  it { should have_many(:skills).class_name(Task::Skill) }
  it { should have_many(:locations).class_name(Location) }
  it { should belong_to(:working_group).class_name(WorkingGroup) }
  it { should belong_to(:discussion).class_name(Discussion) }
end