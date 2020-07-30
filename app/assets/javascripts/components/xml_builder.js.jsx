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

var XmlBuilder = createReactClass({

  propTypes: {
    placements: PropTypes.array,
    baseUrl: PropTypes.string
  },

  getInitialState: function() {
    return {xmlUrl: this.props.baseUrl, generatedXML: "<?xml version='1.0' encoding='utf-8'><test></test></xml>"}
  },

  componentDidMount: function() {
    this.formChangeHandler();
  },

  formChangeHandler: function () {
    var url = this.props.baseUrl + "?" + $(ReactDOM.findDOMNode(this.refs.xmlForm)).serialize();
    $.get(url, function(data) {
      this.setState({
        xmlUrl: url,
        generatedXML: (new XMLSerializer()).serializeToString(data)
      });
    }.bind(this));
  },

  xmlUrlClickHandler: function (e) {
    e.target.setSelectionRange(0, e.target.value.length)
  },

  render: function () {
    var formChangeHandler = this.formChangeHandler;
    return (
      <div className="container">
        <h2 className="text-center">XML Builder</h2>

        <p>
          <label htmlFor="xml-uri">XML URL:</label>
          <input onClick={this.xmlUrlClickHandler} style={{cursor: 'text'}} ref="xmlUrl" id="xml-url" value={this.state.xmlUrl} className="form-control form-read-only" readOnly type="text"/>
        </p>

        <div className="row">
          <div className="col-md-5">
            <form ref="xmlForm" onChange={this.formChangeHandler} method="post">
              <XmlBuilder.Placements ref="placements" placements={this.props.placements}><strong>Select which Placements you
                would like to enable</strong></XmlBuilder.Placements>
              <XmlBuilder.Options ref="ltiOptions"><strong>Set values for width and height</strong></XmlBuilder.Options>
              <XmlBuilder.CustomParams ref="customParams" onFormChange={formChangeHandler} ><strong>Specify Custom Params</strong></XmlBuilder.CustomParams>
            </form>
          </div>
          <div className="col-md-7">
            <p>
              <strong>Live XML Preview</strong>
            </p>
            <div id="generated-xml">
              <pre>
                <code className="xml">
                  {this.state.generatedXML}
                </code>
              </pre>
            </div>
          </div>
        </div>

      </div>
    );
  }

});
