define([
    'react',
    'plugins/analytics/react-bootstrap-table',
    'i18n!analytics'
], function (React, ReactBootstrapTable, I18n) {

    const { BootstrapTable, TableHeaderColumn } = ReactBootstrapTable;

    const tableOptions = {
        sizePerPage: 30,
        sizePerPageList: []
    };

    return React.createClass({
        displayName: 'SubmissionsTable',

        propTypes: {
            data: React.PropTypes.object.isRequired
        },

        formatPercentStyle (styles = {}) {
            styles.fontWeight = 'bold';
            return function (cell, row) {
                return <span style={styles}>{Math.round(Math.floor(Number.parseFloat(cell) * 100))}%</span>;
            }
        },

        render () {
            return (
                <div>
                    <BootstrapTable data={this.props.data} pagination={true} options={tableOptions}>
                        <TableHeaderColumn dataField="title" isKey={true}>{I18n.t("Assignment")}</TableHeaderColumn>
                        <TableHeaderColumn dataField="missing" dataFormat={this.formatPercentStyle()}>{I18n.t("Missing")}</TableHeaderColumn>
                        <TableHeaderColumn dataField="late" dataFormat={this.formatPercentStyle()}>{I18n.t("Late")}</TableHeaderColumn>
                        <TableHeaderColumn dataField="onTime" dataFormat={this.formatPercentStyle()}>{I18n.t("On Time")}</TableHeaderColumn>
                    </BootstrapTable>
                </div>

            );
        }
    });
});

