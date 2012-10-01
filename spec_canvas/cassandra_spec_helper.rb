require File.expand_path(File.dirname(__FILE__) + '/../../../../spec/cassandra_spec_helper')

shared_examples_for "analytics cassandra page views" do
  it_should_behave_like "cassandra page views"
  before do
    if Canvas::Cassandra::Database.configured?('page_views')
      PageView.cassandra.execute("TRUNCATE page_views_counters_by_context_and_user")
      PageView.cassandra.execute("TRUNCATE page_views_counters_by_context_and_hour")
      PageView.cassandra.execute("TRUNCATE participations_by_context")
    end
  end
end
