import React from 'react'
import ReactBootstrapTable from '../../../public/javascripts/react-bootstrap-table'
import { useScope as useI18nScope } from '@canvas/i18n';
import helpers from '../helpers'

const I18n = useI18nScope('analytics');

const {BootstrapTable, TableHeaderColumn} = ReactBootstrapTable

const tableOptions = {
  sizePerPage: 30,
  sizePerPageList: []
}

export default class ActivitiesByCategory extends React.Component {
  static propTypes = {
    data: React.PropTypes.object.isRequired
  }

  formatDate = (cell, row) => I18n.l('date.formats.default', cell)

  formatStyle = (styles = {}) =>
    (function(cell, row) {
      return <span style={styles}>{cell}</span>
    })

  formatNumber = (styles = {}) =>
    (function(cell, row) {
      return <span style={styles}>{helpers.formatNumber(cell)}</span>
    })

  render() {
    return (
      <div>
        <BootstrapTable data={this.props.data} pagination options={tableOptions}>
          <TableHeaderColumn dataField="category" isKey dataFormat={this.formatStyle()}>
            {I18n.t('Category')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="views" dataFormat={this.formatNumber()}>
            {I18n.t('Page Views')}
          </TableHeaderColumn>
        </BootstrapTable>
      </div>
    )
  }
}
