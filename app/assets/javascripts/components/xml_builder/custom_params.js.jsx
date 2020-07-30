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

XmlBuilder.CustomParams = createReactClass({

  propTypes: {
    initialCustomParams: PropTypes.array,
    onFormChange: PropTypes.func
  },

  getInitialState: function () {
    var initialCustomParams = this.props.initialCustomParams || [];
    return {customParams: initialCustomParams};
  },

  addRowHandler: function (e) {
    // prevent refreshing page
    e.stopPropagation();
    e.nativeEvent.stopImmediatePropagation();
    var customParams = this.state.customParams;
    customParams.push( {name: '', value: ''} );
    this.setState( {customParams: customParams} );
  },

  handleDelete: function (index) {
    var customParams = this.state.customParams;
    customParams.splice(index, 1);
    this.setState( {customParams: customParams, updateForm: true} );
  },

  componentDidUpdate(prevProps, prevState) {
    if(this.state.updateForm){
      this.props.onFormChange();
      this.setState( {updateForm: false} );
    }
  },

  render: function () {
    var customParams = this.state.customParams;
    var handleDelete = this.handleDelete;
    return (
      <div>
        <p>{this.props.children}</p>
        <table className="table table-condensed">
          <thead>
          <tr>
            <th>Name</th>
            <th>Value</th>
            <th className="add-remove-col">
              <a onClick={this.addRowHandler} href="#">
                <span className="glyphicon glyphicon-plus add-icon"> </span>
              </a>
            </th>
          </tr>
          </thead>
          <tbody>
          {customParams.map(function (customParam, index) {
            return <XmlBuilder.CustomParams.Row onRowDelete={handleDelete} key={index} index={index} paramName={customParam.name} paramValue={customParam.value} ></XmlBuilder.CustomParams.Row>
          })}
          </tbody>
        </table>
      </div>
    );
  }

});