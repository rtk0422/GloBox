select g.group, count(uid) as total_users
                         From groups g
                        group by g.group
