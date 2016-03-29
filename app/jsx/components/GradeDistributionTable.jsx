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
        displayName: 'GradeDistribution',

        propTypes: {
            data: React.PropTypes.object.isRequired
        },

        formatStyle (styles = {}) {
            return function (cell, row) {
                return <span style={styles}>{cell}</span>;
            }
        },

        formatPercent (styles = {}) {
            return function (cell, row) {
                return <span style={styles}>{cell * 100}%</span>;
            }
        },

        render () {
            return (
                <div>
                    <BootstrapTable data={this.props.data} pagination={true} options={tableOptions}>
                        <TableHeaderColumn dataField="score" isKey={true} dataFormat={this.formatStyle()}>{I18n.t("Score")}</TableHeaderColumn>
                        <TableHeaderColumn dataField="percent" dataFormat={this.formatPercent()}>{I18n.t("Percent of Students Scoring")}</TableHeaderColumn>
                    </BootstrapTable>
                </div>
            );
        }
    });
});


