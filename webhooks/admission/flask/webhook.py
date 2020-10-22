#!/usr/bin/env python

ACCEPTED_COLORS = ["blue", "green", "red"]

import json
import pprint
import yaml

from flask import Flask, request

app = Flask(__name__)


# Since most or all the things that we might want to print are going to
# be Kubernetes resource manifests (or fragments thereof), and these
# manifests are usually represented as YAML, we might as well print them
# as YAML when we need to view them.
def debug(obj):
    app.logger.debug(yaml.dump(obj))


@app.route("/", methods=["POST"])
def webhook():

    payload = json.loads(request.data)
    debug(payload)

    # Let's check that we were called the right way.
    assert payload["kind"] == "AdmissionReview"
    uid = payload["request"]["uid"]
    pod = payload["request"]["object"]
    assert pod["kind"] == "Pod"
    assert pod["apiVersion"] == "v1"

    # If the pod has a "color" label, it has to be one of the accepted ones.
    labels = pod["metadata"].get("labels", {})
    if "color" in labels:
        color = labels["color"]
        if color not in ACCEPTED_COLORS:
            return response(
                uid,
                False,
                "color {!r} is not in the allowed set ({!r})".format(
                    color, ACCEPTED_COLORS
                ),
            )

    # If this is an UPDATE request, oldObject has the old version.
    # (Otherwise, it's null aka None in Python.)
    oldPod = payload["request"]["oldObject"]
    if oldPod:
	    oldLabels = oldPod["metadata"].get("labels", {})
	    # If the pod *had* a "color" label, it cannot be removed.
	    if "color" in oldLabels and "color" not in labels:
	        return response(uid, False, "cannot remove color from a colored pod")
	    # The "color" label also cannot be changed to a different value.
	    if "color" in oldLabels and "color" in labels:
	        if oldLabels["color"] != labels["color"]:
	            return response(uid, False, "cannot change color of a pod")

    # Otherwise, accept the request.
    return response(uid, True)


def response(uid, allowed, message=None):
    payload = {
        "apiVersion": "admission.k8s.io/v1",
        "kind": "AdmissionReview",
        "response": {"uid": uid, "allowed": allowed},
    }
    if message is not None:
        payload["response"]["status"] = {"message": message}
    return payload
