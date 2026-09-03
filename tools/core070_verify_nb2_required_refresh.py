"""Fresh original NB2 required pair after the formula input-validation repair."""
import core070_verify_nb2_required as gate

def verify():
    previous=gate.STATE
    try:
        gate.STATE=gate.ROOT/'.unlazy/core070-aghq/nb2-required-02'
        gate.verify()
    finally:
        gate.STATE=previous

if __name__=='__main__':verify()
