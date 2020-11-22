
"""
tools.jl déclare divers utilitaires
"""

# retourne le nom du node correspondant
function getNameNode(indexNode::Int)
    return string("node_",indexNode)
end