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
        displayName: 'GradesTable',

        propTypes: {
            data: React.PropTypes.object.isRequired
        },

        formatPercentile (cell, row) {
            // The percentile property comes in as an
            // object with "min" and "max" keys to denote
            // the range of the 25th - 75th percentile
            return `${cell.min} - ${cell.max}`;
        },

        formatNumber (styles = {}) {
            return function (cell, row) {
                return <span style={styles}>{I18n.n(cell)}</span>;
            }
        },

        render () {
            if (this.props.student) {
                return (
                    <div>
                        <BootstrapTable data={this.props.data} pagination={true} options={tableOptions}>
                            <TableHeaderColumn dataField="title" isKey={true}>{I18n.t("Assignment")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="student_score" dataFormat={this.formatNumber()}>{I18n.t("Score")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="score_type">{I18n.t("Performance")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="min_score" dataFormat={this.formatNumber()}>{I18n.t("Low")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="median" dataFormat={this.formatNumber()}>{I18n.t("Median")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="max_score" dataFormat={this.formatNumber()}>{I18n.t("High")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="percentile" dataFormat={this.formatPercentile}>{I18n.t("25th-75th %ile")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="points_possible" dataFormat={this.formatNumber()}>{I18n.t("Points Possible")}</TableHeaderColumn>
                        </BootstrapTable>
                    </div>
                );
            } else {
                return (
                    <div>
                        <BootstrapTable data={this.props.data} pagination={true} options={tableOptions}>
                            <TableHeaderColumn dataField="title" isKey={true}>{I18n.t("Assignment")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="min_score" dataFormat={this.formatNumber()}>{I18n.t("Low")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="median" dataFormat={this.formatNumber()}>{I18n.t("Median")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="max_score" dataFormat={this.formatNumber()}>{I18n.t("High")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="percentile" dataFormat={this.formatPercentile}>{I18n.t("25th-75th %ile")}</TableHeaderColumn>
                            <TableHeaderColumn dataField="points_possible" dataFormat={this.formatNumber()}>{I18n.t("Points Possible")}</TableHeaderColumn>
                        </BootstrapTable>
                    </div>
                );
            }
        }
    });
});
