// BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

// Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

// This program is free software; you can redistribute it and/or modify it under the
// terms of the GNU Lesser General Public License as published by the Free Software
// Foundation; either version 3.0 of the License, or (at your option) any later
// version.

// BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

// You should have received a copy of the GNU Lesser General Public License along
// with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

XmlBuilder.Placements = createReactClass({

  propTypes: {
    placements: PropTypes.array
  },

  selectAll: function() {
    $('input.placement').prop('checked', $(ReactDOM.findDOMNode(this.refs.cbSelectAll)).prop('checked'));
  },

  render: function () {
    var placements = this.props.placements;
    return (
      <div>
        <p>{this.props.children}</p>
        <table className="table table-condensed">
          <thead>
          <tr>
            <th className="text-center checkbox-col">
              <input type="checkbox" ref="cbSelectAll" onChange={this.selectAll}/>
            </th>
            <th>Title</th>
            <th>Message Type</th>
          </tr>
          </thead>
          <tbody>
          {placements.map(function (placement) {
            return <XmlBuilder.Placements.Row key={placement.key} placementKey={placement.key} message={placement.message} >{placement.name}</XmlBuilder.Placements.Row>
          })}
          </tbody>
        </table>
      </div>
    );
  }

});
