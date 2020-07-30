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

XmlBuilder.CustomParams.Row = createReactClass({

  propTypes: {
    param_name: PropTypes.string,
    param_value: PropTypes.string,
    index: PropTypes.number.isRequired,
    onRowDelete: PropTypes.func.isRequired
  },

  removeHandler: function (e) {
    // prevent refreshing page
    e.stopPropagation();
    e.nativeEvent.stopImmediatePropagation();

    var index = ReactDOM.findDOMNode(this.refs.index).value.trim();
    this.props.onRowDelete(Number(index));
  },

  render: function () {
    return (
      <tr>
        <td><input ref="paramName" name={"custom_params["+this.props.index+"][name]"} defaultValue={this.props.param_name} type="text"></input></td>
        <td><input ref="paramValue" name={"custom_params["+this.props.index+"][value]"} defaultValue={this.props.param_value} type="text"></input></td>
        <td className="add-remove-col">
          <input type="hidden" ref="index" value={this.props.index}></input>
          <a href="#" onClick={this.removeHandler}>
            <span className="glyphicon glyphicon-minus remove-icon"></span>
          </a>
        </td>
      </tr>
    );
  }

});