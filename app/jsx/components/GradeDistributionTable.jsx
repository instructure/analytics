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

export default class GradeDistribution extends React.Component {
  static propTypes = {
    data: React.PropTypes.object.isRequired
  }

  formatNumber = (styles = {}) =>
    (function(cell, row) {
      return <span style={styles}>{helpers.formatNumber(cell)}</span>
    })

  formatPercent = (styles = {}) =>
    (function(cell, row) {
      return <span style={styles}>{cell * 100}%</span>
    })

  render() {
    return (
      <div>
        <BootstrapTable data={this.props.data} pagination options={tableOptions}>
          <TableHeaderColumn dataField="score" isKey dataFormat={this.formatNumber()}>
            {I18n.t('Score')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="percent" dataFormat={this.formatPercent()}>
            {I18n.t('Percent of Students Scoring')}
          </TableHeaderColumn>
        </BootstrapTable>
      </div>
    )
  }
}
