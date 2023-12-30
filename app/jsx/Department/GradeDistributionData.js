/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import BaseData from '../BaseData'

// Loads the grade distribution data for the current account/filter. Exposes
// the data as the 'values' property once loaded.
export default class GradeDistributionData extends BaseData {
  constructor(filter) {
    const account = filter.get('account')
    const fragment = filter.get('fragment')
    super(`/api/v1/accounts/${account.get('id')}/analytics/${fragment}/grades`)
  }

  populate(data) {
    let cumulative = 0
    for (let i = 0; i <= 100; i++) {
      cumulative += parseInt(data[i], 10)
    }
    if (cumulative === 0) cumulative = 1
    this.values = Array(101)
      .fill()
      .map((_, i) => data[i] / cumulative)
  }
}
