# TODO

## bugs

old ?

```
[2021-03-20 14:33:34,887: ERROR/MainProcess] Received unregistered task of type 'bookwyrm.models.activitypub_mixin.broadcast_task'.
mars 20 15:33:34 activitypub celery[781]: The message has been ignored and discarded.
mars 20 15:33:34 activitypub celery[781]: Did you remember to import the module containing this task?
mars 20 15:33:34 activitypub celery[781]: Or maybe you're using relative imports?
mars 20 15:33:34 activitypub celery[781]: Please see
mars 20 15:33:34 activitypub celery[781]: http://docs.celeryq.org/en/latest/internals/protocol.html
mars 20 15:33:34 activitypub celery[781]: for more information.
mars 20 15:33:34 activitypub celery[781]: The full contents of the message body was:
mars 20 15:33:34 activitypub celery[781]: b'[[1, "{\\"id\\": \\"https://books.rhumbs.fr/user/mmai/review/30/activity\\", \\"type\\": \\"Create\\", \\"actor\\": \\"https://books.rhumbs.fr/user/mmai\\", \\"object\\": {\\"id\\": \\"https://books.rhumbs.fr/user/mmai/review/30\\", \\"type\\": \\"Article\\", \\"published\\": \\"2006-07-25T00:00:00+00:00\\", \\"attributedTo\\": \\"https://books.rhumbs.fr/user/mmai\\", \\"content\\": \\"\\", \\"to\\": [\\"https://www.w3.org/ns/activitystreams#Public\\"], \\"cc\\": [\\"https://books.rhumbs.fr/user/mmai/followers\\"], \\"replies\\": {\\"id\\": \\"https://books.rhumbs.fr/user/mmai/review/30/replies\\", \\"type\\": \\"OrderedCollection\\", \\"totalItems\\": 0, \\"first\\": \\"https://books.rhumbs.fr/user/mmai/review/30/replies?page=1\\", \\"last\\": \\"https://books.rhumbs.fr/user/mmai/review/30/replies?page=1\\", \\"@context\\": \\"https://www.w3.org/ns/activitystreams\\"}, \\"inReplyTo\\": \\"\\", \\"summary\\": \\"\\", \\"tag\\": [], \\"attachment\\": [{\\"id\\": \\"\\", \\"type\\": \\"Image\\", \\"url\\":... (1563b)
mars 20 15:33:34 activitypub celery[781]: Traceback (most recent call last):
mars 20 15:33:34 activitypub celery[781]:   File "/nix/store/vigqjdn458x7bwc5qxg8wc40hyk9n5rk-python3-3.8.8-env/lib/python3.8/site-packages/celery/worker/consumer/consumer.py", line 562, in on_task_received
mars 20 15:33:34 activitypub celery[781]:     strategy = strategies[type_]
```

## base system

* configure backups
