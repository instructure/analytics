Canvas Analytics
================

This is the official analytics package for Instructure's Canvas LMS.

Version
-------

1.0

Dependencies
------------

 * Canvas LMS (https://github.com/instructure/canvas-lms)

Installation
------------

First, have Canvas LMS installed. Then:

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

License
-------

[GNU Affero General Public License v3.0](http://www.gnu.org/licenses/agpl-3.0.html)
