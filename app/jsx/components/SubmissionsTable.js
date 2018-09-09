import React from 'react'
import ReactBootstrapTable from 'plugins/analytics/react-bootstrap-table'
import I18n from 'i18n!analytics'

const {BootstrapTable, TableHeaderColumn} = ReactBootstrapTable

const tableOptions = {
  sizePerPage: 30,
  sizePerPageList: []
}

export default class SubmissionsTable extends React.Component {
  static propTypes = {
    data: React.PropTypes.object.isRequired
  }

  formatPercentStyle = (styles = {}) => {
    styles.fontWeight = 'bold'
    return function(cell, row) {
      return <span style={styles}>{Math.round(Math.floor(Number.parseFloat(cell) * 100))}%</span>
    }
  }

  render() {
    return (
      <div>
        <BootstrapTable data={this.props.data} pagination options={tableOptions}>
          <TableHeaderColumn dataField="title" isKey>
            {I18n.t('Assignment')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="missing" dataFormat={this.formatPercentStyle()}>
            {I18n.t('Missing')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="late" dataFormat={this.formatPercentStyle()}>
            {I18n.t('Late')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="onTime" dataFormat={this.formatPercentStyle()}>
            {I18n.t('On Time')}
          </TableHeaderColumn>
        </BootstrapTable>
      </div>
    )
  }
}
