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

var ContentItemBuilder = createReactClass({

  propTypes: {
    data: PropTypes.string,
    returnUrl: PropTypes.string,
    ltiVersion: PropTypes.string,
    ltiLaunchUrl: PropTypes.string,
    ltiUpdateUrl: PropTypes.string,
    textFileUrl: PropTypes.string,
    videoUrl: PropTypes.string,
    ccFileUrl: PropTypes.string,
    consumerKey: PropTypes.string,
    documentTargets: PropTypes.array,
    mediaTypes: PropTypes.array
  },

  getInitialState: function () {
    return {
      contentItems: {
        "@context": "http://purl.imsglobal.org/ctx/lti/v1/ContentItem",
        "@graph": []
      }
    };
  },

  updateContentItems: function () {
    this.setState({contentItems: this.refs.contentItemsElement.toJSON()});
  },

  render: function () {
    return (
      <div style={{'background': 'white'}} >
        <ContentItemBuilder.ContentItems
          ltiLaunchUrl={this.props.ltiLaunchUrl}
          ltiUpdateUrl={this.props.ltiUpdateUrl}
          textFileUrl={this.props.textFileUrl}
          videoUrl={this.props.videoUrl}
          ccFileUrl={this.props.ccFileUrl}
          documentTargets={this.props.documentTargets}
          mediaTypes={this.props.mediaTypes}
          updateContentItems={this.updateContentItems}
          ref="contentItemsElement"
          />
        <hr/>
        <ContentItemBuilder.ContentItemMessage
          data={this.props.data}
          returnUrl={this.props.returnUrl}
          ltiVersion={this.props.ltiVersion}
          contentItems={this.state.contentItems}
          consumerKey={this.props.consumerKey}
        />
      </div>
    );
  }
});