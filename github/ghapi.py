# Copyright (C) 2015 Synopsys Inc.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.

import http.client
import json
import logging
import mimetypes
import os.path
import ssl

class GitHubApi:

    def __init__(self, owner, project, oauth_token, server="api.github.com",
            uploads_server="uploads.github.com", debuglevel=0):

        logging.debug("Creating GitHub API connection for %s/%s", owner, project)
        self._server = server
        self._connection = http.client.HTTPSConnection(server)
        self._connection.set_debuglevel(debuglevel)
        self._owner = owner
        self._project = project
        self._project_url = "/repos/{0}/{1}".format(owner, project)
        self._http_headers = {
            "Authorization": "token " + oauth_token,
            "User-Agent": "Python",
        }

        # Assets uploads use different server. Also hostname of this server
        # doesn't match it's SSL certificate... Therefore it is required to
        # disable hostname check in it.
        uploads_ssl_context = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
        uploads_ssl_context.check_hostname = False
        self._uploads_server = uploads_server
        self._uploads_connection = http.client.HTTPSConnection(uploads_server,
                context=uploads_ssl_context)
        self._uploads_connection.set_debuglevel(debuglevel)

    def create_release(self, git_tag, name, description, draft, prerelease):
        """Returns release id"""
        logging.info("Creating release %s at %s/%s", name, self._owner, self._project)
        url = self._project_url + "/releases"
        req = {
                "tag_name": git_tag,
                "name": name,
                "body": description,
                "draft": draft,
                "prerelease": prerelease,
        }
        self._connection.request("POST", url, json.dumps(req), self._http_headers)
        response = self._connection.getresponse()
        response_text = response.read().decode("utf-8") # read() returns 'bytes' not 'string'
        logging.debug(response_text)
        response_data = json.loads(response_text)
        return response_data["id"]

    def upload_asset(self, release_id, asset):
        logging.info("Uploading asset: %s", asset)
        name = os.path.basename(asset)
        url = "{0}/releases/{1}/assets?name={2}".format(self._project_url, release_id, name)
        (mime_type, mime_encoding) = mimetypes.guess_type(asset)
        asset_headers = self._http_headers.copy()
        asset_headers["Content-Type"] = mime_type
        logging.debug("Asset Content-Type: %s", mime_type)
        with open(asset, "rb") as f:
            data = f.read()
            self._uploads_connection.request("POST", url, data, asset_headers)
            response = self._uploads_connection.getresponse()
            logging.debug(response.read())

# vi: set expandtab sw=4:
