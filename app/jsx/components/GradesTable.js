import React from 'react'
import ReactBootstrapTable from 'plugins/analytics/react-bootstrap-table'
import I18n from 'i18n!analytics'
import helpers from 'analytics/compiled/helpers'

const {BootstrapTable, TableHeaderColumn} = ReactBootstrapTable

const tableOptions = {
  sizePerPage: 30,
  sizePerPageList: []
}

export default class GradesTable extends React.Component {
  static propTypes = {
    data: React.PropTypes.object.isRequired
  }

  formatPercentile = (cell, row) =>
    // The percentile property comes in as an
    // object with "min" and "max" keys to denote
    // the range of the 25th - 75th percentile
    `${cell.min} - ${cell.max}`

  formatNumber = (styles = {}) =>
    function(cell, row) {
      return <span style={styles}>{helpers.formatNumber(cell)}</span>
    }

  render() {
    if (this.props.student) {
      return (
        <div>
          <BootstrapTable data={this.props.data} pagination options={tableOptions}>
            <TableHeaderColumn dataField="title" isKey>
              {I18n.t('Assignment')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="student_score" dataFormat={this.formatNumber()}>
              {I18n.t('Score')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="score_type">{I18n.t('Performance')}</TableHeaderColumn>
            <TableHeaderColumn dataField="min_score" dataFormat={this.formatNumber()}>
              {I18n.t('Low')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="median" dataFormat={this.formatNumber()}>
              {I18n.t('Median')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="max_score" dataFormat={this.formatNumber()}>
              {I18n.t('High')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="percentile" dataFormat={this.formatPercentile}>
              {I18n.t('25th-75th %ile')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="points_possible" dataFormat={this.formatNumber()}>
              {I18n.t('Points Possible')}
            </TableHeaderColumn>
          </BootstrapTable>
        </div>
      )
    } else {
      return (
        <div>
          <BootstrapTable data={this.props.data} pagination options={tableOptions}>
            <TableHeaderColumn dataField="title" isKey>
              {I18n.t('Assignment')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="min_score" dataFormat={this.formatNumber()}>
              {I18n.t('Low')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="median" dataFormat={this.formatNumber()}>
              {I18n.t('Median')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="max_score" dataFormat={this.formatNumber()}>
              {I18n.t('High')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="percentile" dataFormat={this.formatPercentile}>
              {I18n.t('25th-75th %ile')}
            </TableHeaderColumn>
            <TableHeaderColumn dataField="points_possible" dataFormat={this.formatNumber()}>
              {I18n.t('Points Possible')}
            </TableHeaderColumn>
          </BootstrapTable>
        </div>
      )
    }
  }
}
