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

ContentItemBuilder.ContentItemMessage = createReactClass({

  propTypes: {
    data: PropTypes.string,
    returnUrl: PropTypes.string,
    ltiVersion: PropTypes.string,
    consumerKey: PropTypes.string,
    contentItems: PropTypes.object
  },

  getInitialState: function () {
    return {
      ltiMsg: "",
      ltiLog: "",
      ltiErrorMsg: "",
      ltiErrorLog: ""
    };
  },

  formChangeHandler: function (e) {
    var state = {};
    state[e.target.id] = e.target.value;
    this.setState(state);
  },

  formSubmitHandler: function () {
    ReactDOM.findDOMNode(this.refs.contentItemForm).submit();
  },

  render: function () {
    return (
      <div>
        <ContentItemBuilder.ContentItemForm
          ref="contentItemForm"
          data={this.props.data}
          contentItems={this.props.contentItems}
          returnUrl={this.props.returnUrl}
          ltiVersion={this.props.ltiVersion}
          consumerKey={this.props.consumerKey}
          ltiMsg={this.state.ltiMsg}
          ltiLog={this.state.ltiLog}
          ltiErrorMsg={this.state.ltiErrorMsg}
          ltiErrorLog={this.state.ltiErrorLog}
          />
        <table>
          <tbody>
          <tr>
            <td>
              <label htmlFor="ltiLog">LTI Log</label>
            </td>
            <td>
              <input onChange={this.formChangeHandler} value={this.state.ltiLog} id="ltiLog" type="text"/>
            </td>
          </tr>
          <tr>
            <td>
              <label htmlFor="ltiMsg">LTI Message</label>
            </td>
            <td>
              <input onChange={this.formChangeHandler} value={this.state.ltiMsg} id="ltiMsg" type="text"/>
            </td>
          </tr>
          <tr>
            <td>
              <label htmlFor="ltiErrorMsg">LTI Error Message</label>
            </td>
            <td>
              <input onChange={this.formChangeHandler} value={this.state.ltiErrorMsg} id="ltiErrorMsg" type="text"/>
            </td>
          </tr>
          <tr>
            <td>
              <label htmlFor="ltiErrorLog">LTI Error Log</label>
            </td>
            <td>
              <input onChange={this.formChangeHandler} value={this.state.ltiErrorLog} id="ltiErrorLog" type="text"/>
            </td>
          </tr>
          <tr>
            <td></td>
            <td>
              <button onClick={this.formSubmitHandler} type="button">Submit</button>
            </td>
          </tr>
          </tbody>
        </table>
      </div>

    );
  }

});