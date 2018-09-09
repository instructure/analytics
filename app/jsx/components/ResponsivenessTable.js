import React from 'react'
import ReactBootstrapTable from 'plugins/analytics/react-bootstrap-table'
import I18n from 'i18n!analytics'
import helpers from 'analytics/compiled/helpers'

const {BootstrapTable, TableHeaderColumn} = ReactBootstrapTable

const tableOptions = {
  sizePerPage: 30,
  sizePerPageList: []
}

export default class ResponsivenessTable extends React.Component {
  static propTypes = {
    data: React.PropTypes.object.isRequired
  }

  formatDate = (cell, row) => I18n.l('date.formats.default', cell)

  formatNumber = (styles = {}) => {
    styles.fontWeight = 'bold'
    return function(cell, row) {
      return <span style={styles}>{helpers.formatNumber(cell)}</span>
    }
  }

  render() {
    return (
      <div>
        <BootstrapTable data={this.props.data} pagination options={tableOptions}>
          <TableHeaderColumn dataField="date" isKey dataFormat={this.formatDate}>
            {I18n.t('Date')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="instructorMessages" dataFormat={this.formatNumber()}>
            {I18n.t('Instructor Messages')}
          </TableHeaderColumn>
          <TableHeaderColumn dataField="studentMessages" dataFormat={this.formatNumber()}>
            {I18n.t('Student Messages')}
          </TableHeaderColumn>
        </BootstrapTable>
      </div>
    )
  }
}
