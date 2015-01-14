Canvas Analytics
================

This is the official analytics package for Instructure's Canvas LMS.

Version
-------

1.0

Dependencies
------------

 * Canvas LMS (https://github.com/instructure/canvas-lms)
 * Cassandra (http://www.datastax.com/docs/1.1/index)

Cassandra is already an optional component of installing the Canvas LMS,
but it is **strongly encouraged** when running this analytics package.
See the comments in [Canvas' example Cassandra
configuration](https://github.com/instructure/canvas-lms/blob/stable/config/cassandra.yml.example)
for details on setting up Cassandra in Canvas.

Analytics' usage of Cassandra falls into the same keyspace as Cassandra
backed PageViews.

Installation
------------

First, have Canvas LMS installed with Cassandra backed Page Views
enabled. Then:

```sh
cd [canvas-rails-root]
git clone [analytics-repo-url] gems/plugins/analytics
bundle update
rake db:migrate
rake canvas:compile_assets
```

In your browser, login to your Canvas application and visit
`/accounts/self/settings`. Under features, enable the `Analytics`
checkbox.

Visit `/accounts/self/analytics` to verify.

Running without Cassandra (NOT RECOMMENDED)
-------------------------------------------

It's been a long time since we tried to run this analytics package
without Cassandra backing. It **might** still be possible, but we
haven't verified it and do not support it under that configuration.

The relevant code for running without Cassandra backing is described in
the `Analytics::PageViewIndex::DB` module in the
`lib/analytics/page_view_index.rb` file. This code has **NOT** been
exercised or maintained lately, and may be buggy. Use this configuration
at your own risk.

Even if that code works properly, we abandoned it in favor of Cassandra
backed rollups and indices for performance reasons. Even with a
relatively small Canvas instance, it is likely you may run into similar
performance issues when using the naïve DB backing for analytics.

If after reading all of the above you still want to run analytics
without Cassandra, the installation is exactly as above. The Cassandra
migrations in `db/migrations/` will automatically be skipped.

License
-------

[GNU Affero General Public License v3.0](http://www.gnu.org/licenses/agpl-3.0.html)
