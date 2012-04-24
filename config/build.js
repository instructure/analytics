({

  // file optimizations
  optimize: "uglify",

  // continue to let Jammit do its thing
  optimizeCss: "none",

  // where to place optimized javascript, relative to this file
  dir: "../public/optimized",

  // where the "app" is, relative to this file
  appDir: "../public/javascripts",

  // base path for modules, relative to appDir
  baseUrl: "./",

  translate: true,

  // paths we have set up (matches require onfig in application.html.erb)
  paths: {
    jquery: '../../../../../public/javascripts/vendor/jquery-1.6.4',
    jqueryui: '../../../../../public/javascripts/vendor/jqueryui',
    underscore: '../../../../../public/javascripts/underscore',
    Backbone: '../../../../../public/javascripts/Backbone',
    uploadify: '../../../../../public/flash/uploadify/jquery.uploadify.v2.1.4',
    use: '../../../../../public/javascripts/vendor/use',
    common: '../../../../../public/javascripts/compiled/bundles/common',

    // everything pulled in by either handlebars_helpers or common (when it's
    // seeing what to exclude). awesome
    'INST': '../../../../../public/javascripts/INST',
    'ajax_errors': '../../../../../public/javascripts/ajax_errors',
    'compiled/backbone-ext': '../../../../../public/javascripts/compiled/backbone-ext',
    'compiled/editor': '../../../../../public/javascripts/compiled/editor',
    'compiled/fn': '../../../../../public/javascripts/compiled/fn',
    'compiled/handlebars_helpers': '../../../../../public/javascripts/compiled/handlebars_helpers',
    'compiled/helpDialog': '../../../../../public/javascripts/compiled/helpDialog',
    'compiled/jquery': '../../../../../public/javascripts/compiled/jquery',
    'compiled/license_help': '../../../../../public/javascripts/compiled/license_help',
    'compiled/tinymce': '../../../../../public/javascripts/compiled/tinymce',
    'compiled/util': '../../../../../public/javascripts/compiled/util',
    'compiled/widget': '../../../../../public/javascripts/compiled/widget',
    'compiled/behaviors': '../../../../../public/javascripts/compiled/behaviors',
    'i18n': '../../../../../public/javascripts/i18n',
    'i18nObj': '../../../../../public/javascripts/i18nObj',
    'instructure': '../../../../../public/javascripts/instructure',
    'instructure-jquery.ui.draggable-patch': '../../../../../public/javascripts/instructure-jquery.ui.draggable-patch',
    'instructure_helper': '../../../../../public/javascripts/instructure_helper',
    'jquery.ajaxJSON': '../../../../../public/javascripts/jquery.ajaxJSON',
    'jquery.disableWhileLoading': '../../../../../public/javascripts/jquery.disableWhileLoading',
    'jquery.doc_previews': '../../../../../public/javascripts/jquery.doc_previews',
    'jquery.dropdownList': '../../../../../public/javascripts/jquery.dropdownList',
    'jquery.fancyplaceholder': '../../../../../public/javascripts/jquery.fancyplaceholder',
    'jquery.fixDialogButtons': '../../../../../public/javascripts/jquery.fixDialogButtons',
    'jquery.google-analytics': '../../../../../public/javascripts/jquery.google-analytics',
    'jquery.inst_tree': '../../../../../public/javascripts/jquery.inst_tree',
    'jquery.instructure_date_and_time': '../../../../../public/javascripts/jquery.instructure_date_and_time',
    'jquery.instructure_forms': '../../../../../public/javascripts/jquery.instructure_forms',
    'jquery.instructure_jquery_patches': '../../../../../public/javascripts/jquery.instructure_jquery_patches',
    'jquery.instructure_misc_helpers': '../../../../../public/javascripts/jquery.instructure_misc_helpers',
    'jquery.instructure_misc_plugins': '../../../../../public/javascripts/jquery.instructure_misc_plugins',
    'jquery.keycodes': '../../../../../public/javascripts/jquery.keycodes',
    'jquery.loadingImg': '../../../../../public/javascripts/jquery.loadingImg',
    'jquery.rails_flash_notifications': '../../../../../public/javascripts/jquery.rails_flash_notifications',
    'jquery.scrollToVisible': '../../../../../public/javascripts/jquery.scrollToVisible',
    'jquery.templateData': '../../../../../public/javascripts/jquery.templateData',
    'jst/courseList': '../../../../../public/javascripts/jst/courseList',
    'jst/helpDialog': '../../../../../public/javascripts/jst/helpDialog',
    'link_enrollment': '../../../../../public/javascripts/link_enrollment',
    'mathquill': '../../../../../public/javascripts/mathquill',
    'media_comments': '../../../../../public/javascripts/media_comments',
    'order': '../../../../../public/javascripts/order',
    'page_views': '../../../../../public/javascripts/page_views',
    'reminders': '../../../../../public/javascripts/reminders',
    'str': '../../../../../public/javascripts/str',
    'tinymce': '../../../../../public/javascripts/tinymce',
    'tinymce.editor_box': '../../../../../public/javascripts/tinymce.editor_box',
    'translations': '../../../../../public/javascripts/translations',
    'tricktiny': '../../../../../public/javascripts/tricktiny',
    'vendor': '../../../../../public/javascripts/vendor',
    'wikiSidebar': '../../../../../public/javascripts/wikiSidebar',
    'ENV': '../../../../../public/javascripts/ENV',

    // finally, us
    analytics: "."
  },

  // non-amd shims
  use: {
    'vendor/backbone': {
      deps: ['underscore', 'jquery'],
      attach: function(_, $){
        return Backbone;
      }
    }
  },

  // which modules should have their dependencies concatenated into them
  modules: [
    { name: "compiled/bundles/inject_roster_analytics", exclude: ['common'] },
    { name: "compiled/bundles/inject_roster_user_analytics", exclude: ['common'] },
    { name: "compiled/bundles/user_in_course", exclude: ['common'] }
  ]
})

