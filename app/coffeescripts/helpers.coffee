define [
  'jquery',
  'i18n!analytics',
  'vendor/date'
], ($, I18n) ->

  # returns midnight for the given datetime. with mode 'floor' (the default)
  # it's the nearest preceding (or equal) midnight. with mode 'ceil' it's the
  # nearest following (or equal) midnight.
  midnight: (datetime, mode='floor') ->
    result = datetime.clone().clearTime()
    switch mode
      when 'floor' then result
      when 'ceil'
        if result.compareTo(datetime) is 0
          result
        else
          result.addDays(1)

  # returns the integer number of days that endDate is from startDate. assumes
  # the time portions of startDate and endDate are within an hour (not
  # necessarily equal, thanks to DST) of each other (typically both are
  # midnight), though it can tolerate up to 11 hours difference and still be
  # accurate.
  daysBetween: (startDate, endDate) ->
    Math.round((endDate.getTime() - startDate.getTime()) / 86400000)

  formatNumber: (value) ->
    if typeof value is 'number'
      I18n.n(value)
    else
      I18n.t("N/A")

  ###
  # This method is bad.  It's terrible code.  I feel bad for writing it.
  # It should be removed as soon as able.  I'm doing it so that we can avoid
  # jumping into a built version of the table library and modifing stuff.
  # This would be potentially very bad in the future since that *could* be
  # overwritten.  Once we can use webpack/modern js then we can submit
  # a PR back upstream to add these features to the library itself assuming
  # they aren't already fixed in newer versions anyway.
  #
  # So yes, I know this is a terrible way to do this, but it works.
  ###
  makePaginationAccessible: (tableScopeDiv) ->
    # set up active link switching
    $("#{tableScopeDiv} .pagination").on('click', 'li a', (e) ->
      $("#{tableScopeDiv} .pagination li a").toArray().forEach((element) ->
        $(element).removeAttr('aria-pressed')
      )
      $clickedLink = $(e.currentTarget)
      text = $clickedLink.text()
      # Make sure we don't set the prev/next buttons to pressed
      if (/\d/.test(text))
        $clickedLink.attr('aria-pressed', true)
    )

    $("#{tableScopeDiv} .pagination li a").toArray().forEach((element) ->
      $link = $(element)

      # Take care of the next/previous buttons
      if $link.text() == '<'
        $link.attr('aria-label', I18n.t('Goto previous page'))
      else if $link.text() == '<<'
        $link.attr('aria-label', I18n.t('Goto first page'))
      else if $link.text() == '>'
        $link.attr('aria-label', I18n.t('Goto next page'))
      else if $link.text() == '>>'
        $link.attr('aria-label', I18n.t('Goto last page'))
      else
        # handle adding the 'Goto page X' portion
        pageNum = $link.text()
        $link.attr('aria-label', I18n.t('Goto page %{page_num}', {page_num: pageNum}))

      # Make all the links into buttons... lying to the DOM... shame
      $link.attr('role', 'button')

    )

    $activeLink = $("#{tableScopeDiv} .pagination li.active").children('a')
    $activeLink.attr('aria-pressed', true)
