# Copyright (C) 2015-2017 Synopsys Inc.
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


class GitHubApiException(Exception):
    """General exception type for GitHub related REST API failures"""


def create_ssl_context():
    """Create an insecure context for SSL connection"""
    context = ssl.create_default_context()
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    return context


class GitHubApi:

    def __init__(self, owner, repo, oauth_token, server="api.github.com",
                 uploads_server="uploads.github.com", debuglevel=0):
        logging.debug("Creating GitHub API connection for %s/%s", owner, repo)
        self._server = server
        self._connection = http.client.HTTPSConnection(server,
                                                       context=create_ssl_context())
        self._connection.set_debuglevel(debuglevel)
        self._owner = owner
        self._project = repo
        self._project_url = f"/repos/{owner}/{repo}"
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

    def _request(self, method, url, request=None):
        self._connection.request(
            method, url, json.dumps(request), self._http_headers)
        response = self._connection.getresponse()
        response_body = response.read().decode("utf-8")

        try:
            response_data = json.loads(str(response_body))
        except json.decoder.JSONDecodeError:
            response_data = str(response_body)

        return response.status, response_data

    def create_release(self, tag, name, description, draft, prerelease):
        """Returns release id"""
        logging.info("Creating release \'%s\' at \'%s/%s\'", tag, self._owner,
                     self._project)
        url = self._project_url + "/releases"
        req = {
            "tag_name": tag,
            "name": name,
            "body": description,
            "draft": draft,
            "prerelease": prerelease,
        }
        status, response_data = self._request("POST", url, req)
        if status != 201:
            raise GitHubApiException(response_data["message"])

        return response_data["id"]

    def last_commit_hash_on_branch(self, branch):
        """Get last commit hash on branch"""
        logging.info("Get last commit on branch: \'%s\' at \'%s/%s\'", branch,
                     self._owner,
                     self._project)
        url = self._project_url + f"/commits/{branch}"
        status, response_data = self._request("GET", url)

        if status != 200:
            raise GitHubApiException(response_data["message"])

        return response_data["sha"]

    def create_tag_reference(self, ref, sha):
        """Create a tag reference with GitHub REST API"""
        logging.info("Create tag reference \'%s\' at \'%s/%s\'", ref, self._owner,
                     self._project)
        url = self._project_url + "/git/refs"

        req = {
            "ref": f"refs/tags/{ref}",
            "sha": sha
        }
        status, response_data = self._request("POST", url, req)
        if status != 201:
            raise GitHubApiException(response_data["message"])

    def delete_tag_reference(self, ref):
        """Delete a tag reference with GitHub REST API"""
        logging.info("Delete tag \'%s\' at \'%s/%s\'",
                     ref, self._owner, self._project)
        url = self._project_url + f"/git/refs/tags/{ref}"

        status, response_data = self._request("DELETE", url)

        if status != 204:
            raise GitHubApiException(response_data['message'])

    def upload_asset(self, release_id, asset):
        """Upload release assets with GitHub REST API"""
        logging.info("Uploading asset: %s", asset)
        name = os.path.basename(asset)
        url = "{0}/releases/{1}/assets?name={2}".format(self._project_url, release_id,
                                                        name)
        (mime_type, _) = mimetypes.guess_type(asset)
        asset_headers = self._http_headers.copy()
        asset_headers["Content-Type"] = mime_type
        logging.debug("Asset Content-Type: %s", mime_type)
        with open(asset, "rb") as asset_file:
            data = asset_file.read()
            self._uploads_connection.request("POST", url, data, asset_headers)
            response = self._uploads_connection.getresponse()
            logging.debug(response.read())
