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

export default class ActivitiesTable extends React.Component {
  static propTypes = {
    data: React.PropTypes.object.isRequired
  }

  formatDate = (cell, row) => I18n.l('date.formats.default', cell)

  formatNumber = (styles = {}) =>
    (function(cell, row) {
      return <span style={styles}>{helpers.formatNumber(cell)}</span>
    })

  render() {
    return (
      <div>
        <BootstrapTable data={this.props.data} pagination options={tableOptions}>
          <TableHeaderColumn dataField="date" isKey dataFormat={this.formatDate}>
            {I18n.t('Date')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="views" dataFormat={this.formatNumber()}>
            {I18n.t('Page Views')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="participations" dataFormat={this.formatNumber()}>
            {I18n.t('Actions Taken')}
          </TableHeaderColumn>
        </BootstrapTable>
      </div>
    )
  }
}
