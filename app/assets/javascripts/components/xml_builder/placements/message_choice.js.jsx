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

XmlBuilder.Placements.MessageChoice = createReactClass({
    render: function() {
        if (this.props.messages) {
            var messages = this.props.messages;
            var title = this.props.title
            return (
                <select name={ this.props.placementKey + '_message_type' } >
                    {messages.map(function(message){
                        return (<option key={ title + '  Message Type' + message } name={ title + '  Message Type' } value={ message } >{ message }</option>);
                    })}
                </select>
            );
        } else {
            return false;
        }
    }
});
