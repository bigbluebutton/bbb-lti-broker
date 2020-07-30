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

ContentItemBuilder.ContentItems.Row = createReactClass({

  propTypes: {
    onRowDelete: PropTypes.func.isRequired,
    onRowChange: PropTypes.func.isRequired,
    index: PropTypes.number.isRequired,
    documentTargets: PropTypes.array.isRequired,
    mediaTypes: PropTypes.array.isRequired,
    title: PropTypes.string,
    text: PropTypes.string,
    icon: PropTypes.string,
    thumbnail: PropTypes.string,
    type: PropTypes.string,
    width: PropTypes.string,
    height: PropTypes.string,
    presentationTarget: PropTypes.string,
    windowTarget: PropTypes.string,
    confirmUrl: PropTypes.string,
    canvasVisibility: PropTypes.string
  },

  removeHandler: function (e) {
    // prevent refreshing page
    e.stopPropagation();
    e.nativeEvent.stopImmediatePropagation();
    
    var index = ReactDOM.findDOMNode(this.refs.index).value.trim();
    this.props.onRowDelete(Number(index));
  },

  tableChangeHandler: function (e) {
    var index = ReactDOM.findDOMNode(this.refs.index).value.trim();

    var state = {};
    state[e.target.id] = e.target.value;
    this.setState(state);

    this.props.onRowChange(Number(index), [e.target.id, e.target.value]);
  },

  render: function () {
    var documentTargets = this.props.documentTargets;
    var mediaTypes = this.props.mediaTypes;


    if (mediaTypes.length > 0) {
      return (
        <tr>
          <td><input ref="itemTitle" id="title" onChange={this.tableChangeHandler} defaultValue={this.props.title} type="text"></input></td>
          <td><input ref="itemText" id="text" onChange={this.tableChangeHandler} defaultValue={this.props.text} type="text"></input></td>
          <td><input ref="icon" id="icon" onChange={this.tableChangeHandler} defaultValue={this.props.icon && this.props.icon} type="text"></input></td>
          <td><input ref="thumbnail" id="thumbnail" onChange={this.tableChangeHandler} defaultValue={this.props.thumbnail && this.props.thumbnail} type="text"></input></td>
          <td>
            <select ref="itemType" id="type" onChange={this.tableChangeHandler}>
              {mediaTypes.map(function (value) {
                return <option key={value} value={value}>{value === 'CC' ? 'File Item' : value}</option>
              })};
            </select>
          </td>
          <td>
            <select ref="itemPresentTarget" id="presentationTarget" onChange={this.tableChangeHandler}>
              {documentTargets.map(function (value) {
                return <option key={value} value={value}>{value}</option>
              })};
            </select>
          </td>
          <td><input ref="itemWindowTarget" id="windowTarget" onChange={this.tableChangeHandler} defaultValue={this.props.itemWindowTarget} type="text"></input></td>
          <td><input ref="itemConfirmUrl" id="confirmUrl" onChange={this.tableChangeHandler} defaultValue={this.props.confirmUrl}
          type="text"></input></td>
          <td className="add-remove-col">
            <input type="hidden" ref="index" value={this.props.index}></input>
            <a href="#" onClick={this.removeHandler}>
              <span className="glyphicon glyphicon-minus remove-icon"></span>
            </a>
          </td>
        </tr>
      );
    }

    return (
      <tr>
        <td colSpan="6" style={{textAlign: 'center'}}>
          <strong>No Supported Types</strong>
        </td>
      </tr>
    );
  }

});
