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

ContentItemBuilder.ContentItemForm = createReactClass({

  propTypes: {
    data: PropTypes.string,
    returnUrl: PropTypes.string,
    ltiVersion: PropTypes.string,
    contentItems: PropTypes.object,
    ltiMsg: PropTypes.string,
    ltiLog: PropTypes.string,
    ltiErrorMsg: PropTypes.string,
    LtiErrorLog: PropTypes.string,
    consumerKey: PropTypes.string,
  },


  render: function () {
    if (this.props.contentItems['@graph'] && this.props.contentItems['@graph'].length === 0) {
      this.props.contentItems['@graph'].push({
        "@type": '',
        "@id": '',
        "url": '',
        "title": '',
        "text": '',
        "mediaType": '',
        "placementAdvice": {
          "displayWidth": '',
          "presentationDocumentTarget": '',
          "displayHeight": ''
        }
      });
    }

    var contentItems = this.props.contentItems.contentItems || this.props.contentItems;

    return (
      <form ref="contentItemForm" action="signed_content_item_request" method="post" id="contentItemForm">
        <input type="hidden" name="lti_message_type" value="ContentItemSelection"/>
        <input type="hidden" name="lti_version" value={this.props.ltiVersion}/>
        <input type="hidden" name="oauth_consumer_key" value={this.props.consumerKey}/>
        <input type="hidden" name="data" value={this.props.data}/>
        <input type="hidden" name="content_items" value={JSON.stringify(contentItems)}/>
        <input type="hidden" name="lti_msg" value={this.props.ltiMsg}/>
        <input type="hidden" name="lti_log" value={this.props.ltiLog}/>
        <input type="hidden" name="lti_errormsg" value={this.props.ltiErrorMsg}/>
        <input type="hidden" name="lti_errorlog" value={this.props.ltiErrorLog}/>
        <input type="hidden" name="return_url" value={this.props.returnUrl}/>
      </form>
    );
  },

  //called from parent via ref attribute
  submit: function() {
    ReactDOM.findDOMNode(this.refs.contentItemForm).submit();
  }

});