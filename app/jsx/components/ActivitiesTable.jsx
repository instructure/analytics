define([
    'react',
    'plugins/analytics/react-bootstrap-table',
    'i18n!analytics',
    'jquery',
], function (React, ReactBootstrapTable, I18n, $) {

    const { BootstrapTable, TableHeaderColumn } = ReactBootstrapTable;

    const tableOptions = {
        sizePerPage: 30,
        sizePerPageList: []
    };

    return React.createClass({
        displayName: 'ActivitiesTable',

        propTypes: {
            data: React.PropTypes.object.isRequired
        },

        formatDate (cell, row) {
            return I18n.l("date.formats.default", cell);
        },

        formatNumber (styles = {}) {
            return function (cell, row) {
                return <span style={styles}>{I18n.n(cell)}</span>;
            }
        },

        render () {
            return (
                <div>
                    <BootstrapTable data={this.props.data} pagination={true} options={tableOptions}>
                        <TableHeaderColumn dataField="date" isKey={true} dataFormat={this.formatDate}>{I18n.t("Date")}</TableHeaderColumn>
                        <TableHeaderColumn dataField="views" dataFormat={this.formatNumber()}>{I18n.t("Page Views")}</TableHeaderColumn>
                        <TableHeaderColumn dataField="participations" dataFormat={this.formatNumber()}>{I18n.t("Actions Taken")}</TableHeaderColumn>
                    </BootstrapTable>
                </div>
            );
        }
    });
});
