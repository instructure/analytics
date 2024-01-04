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

import {extend} from 'lodash'
import BaseData from '../BaseData'

// #
// Loads the statistics data for the current account/filter. Exposes
// the data as named properties once loaded.
export default class StatisticsData extends BaseData {
  constructor(filter) {
    const account = filter.get('account')
    const fragment = filter.get('fragment')
    super(`/api/v1/accounts/${account.get('id')}/analytics/${fragment}/statistics`)
  }

  populate(data) {
    return extend(this, data)
  }
}
