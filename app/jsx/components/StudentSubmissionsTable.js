import React from 'react'
import ReactBootstrapTable from 'plugins/analytics/react-bootstrap-table'
import I18n from 'i18n!analytics'
import helpers from 'analytics/compiled/helpers'

const {BootstrapTable, TableHeaderColumn} = ReactBootstrapTable

const tableOptions = {
  sizePerPage: 30,
  sizePerPageList: []
}

export default class StudentSubmissionsTable extends React.Component {
  static propTypes = {
    data: React.PropTypes.object.isRequired
  }

  formatStyle = (styles = {}) => {
    styles.fontWeight = 'bold'
    return function(cell, row) {
      return <span style={styles}>{cell}</span>
    }
  }

  formatNumber = (styles = {}) =>
    function(cell, row) {
      return <span style={styles}>{helpers.formatNumber(cell)}</span>
    }

  formatDate = (cell, row) => {
    if (!cell) return I18n.t('N/A')
    return I18n.l('date.formats.default', cell)
  }

  render() {
    return (
      <div>
        <BootstrapTable data={this.props.data} pagination options={tableOptions}>
          <TableHeaderColumn dataField="title" isKey>
            {I18n.t('Assignment Name')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="status">{I18n.t('Status')}</TableHeaderColumn>
          <TableHeaderColumn dataField="dueAt" dataFormat={this.formatDate}>
            {I18n.t('Due At')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="submittedAt" dataFormat={this.formatDate}>
            {I18n.t('Submitted At')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="score" dataFormat={this.formatNumber()}>
            {I18n.t('Score')}
          </TableHeaderColumn>
        </BootstrapTable>
      </div>
    )
  }
}
