'''
Using motifs in ecological networks to identify the role of plants in crop margins for multiple ecosystem service provision
Julia Tavella*, Fredric M. Windsor, Débora C. Rother, Darren M. Evans, Paulo R. Guimarães Jr., Tania P. Palacios, Marcelo Lois,  Mariano Devoto
*juliatavella@gmail.com
'''
#Preparing data
setwd("C:\\Users\\julia\\Dropbox\\posdoc RS\\SPECIES' ROLES\\DEFINITIVOS\\")
datita<-read.table("Tabla_final_definitiva.csv", sep=",",header=T)
head(datita)

library(tidyverse)
library(igraph)
library(Cairo)

arrange(datita,Field,lower_species,upper_species)#order rows
head(datita)
agrupar<-group_by(datita,Field,lower_species,upper_species,lower_type,upper_type,interaction_type)#group repeated rows
agrupar

#filter(agrupar,Field=="536")
#cuenta_filas<-summarise(agrupar,count=n())#cuenta cant de filas
#cuenta_filas

suma_filas<-summarise(agrupar,sum(N_individuals))
suma_filas

tabla_total<-data.frame(suma_filas)
colnames(tabla_total)=c("Field","from","to","guild1","guild2","interaction_type","weight")
names(tabla_total)
tabla_total
head(tabla_total)

#save as .csv dataset
write.table(tabla_total, file = "definitiva_ordenada.csv", sep = ",", row.names=F)##guardo l

#Key species in motifs
'''
Pre: list of interactions. indicate lower level species in column 'From' and higher level in 'to'
Example:
Field	from	to	guild1	guild2	interaction_type	weight
536	Carduus_acanthoides	Apis_mellifera	plant	pollinator	pollination	2
536	Glycine_max	Palpada_34	plant	pollinator	pollination	2
536	Glycine_max	Rachiplusia_nu	plant	lepidoptera	herbivory	5
536	H1_H5_H11	Achyra_bifidalis	plant	lepidoptera	herbivory	15
536	H1_H5_H11	Lepi_18	plant	lepidoptera	herbivory	2
536	H1_H5_H11	Tatochila_sp	plant	lepidoptera	herbivory	1

Pos: a list of plant-insect interactions contained in motifs
'''

##########################################
####***MOTIFS IN BIPARTITE NETWORKS***####
##########################################
##to study pollination or herbivory motifs

planilla<-read.table("definitiva_ordenada.csv", sep=",",header=T)

#Selection by Field
unique(planilla$Field)
by.field<-planilla[planilla$Field=="536",]###voy cambiando numero aca  536 537 538 540 541 542 543 544 546 547 548 549 550 551 552 553 554 555 556 557 558

#Selection of interaction type   
INT<-<-by.field[by.field$interaction_type=="pollination",] #herbivory or pollination
head(INT)

colnames(INT)=c("Field","lower.taxon","upper.taxon","guild1","guild2","interaction_type","weight")
names(INT)
INT
head(INT)



####Interactions soybean-insects
polin<-function(INT){
			level.superior<-NULL
			for(i in 1:length(INT[,3])){
					if (INT[i,"lower.taxon"]=="Glycine_max"){
      				up.tax<- INT[i,"upper.taxon"]
					level.superior[i]<-as.character(up.tax)
					}else{
						level.superior[i]<-"no"
						}
			}
			return(level.superior)
}


poli_en_motif<-data.frame(polin(INT))
poli_en_motif2<-cbind(INT$lower.taxon, poli_en_motif,INT$weight)
poli_en_motif1<-data.frame(poli_en_motif2[poli_en_motif2$polin.INT != "no",])#output data subset with interactions
colnames(poli_en_motif1)<-c("low.level","high.level","weight")
poli_en_motif1

####Detecting plants from the edges that are participating on motif.  
###Insect-plant from the edge
planta.edge<-function(INT,k){
	level.inferior<-NULL
	for(i in 1:length(INT[,1])){
		if (INT[i,"upper.taxon"]==as.character(k)){ 
    		low.tax<- INT[i,"lower.taxon"]
		level.inferior[i]<-as.character(low.tax)
			}else{
			level.inferior[i]<-"no"
			}
	}
	return(level.inferior)
}

#insects associated to soybean crop
amigos<-as.character(poli_en_motif1[,2])#insects participating in motifs

#function including planta.edge function (for each partner insect in soybean crop...)
total1<-function(INT,amigos){
	final<-matrix(NA,nrow(INT),length(amigos))
	for (j in 1:length(amigos)){ #para cada companero de soja
		k<-amigos[j]
		final[,j]<-planta.edge(INT,k)#busco sus plantas compa;eras de borde
	}
	return(final)
}

matriz.compas<-total1(INT,amigos)
colnames(matriz.compas)=amigos


####Filtered list of interactions participating of motifs
ultimo<-function(matriz.compas,INT){
	tabla.final<-NULL #
	n.columnas<-ncol(matriz.compas)
	for (i in 1:n.columnas){
		seleccionada<-data.frame(matriz.compas[,i])
		subgrupo<-cbind(seleccionada,as.character(INT$upper.taxon),INT$weight)	
		subgrupo1<-subgrupo[subgrupo[,1] != "no",]
		colnames(subgrupo1)<-c("low.level","high.level","weight")
		tabla.final[[i]]<-subgrupo1
	}
	return(tabla.final)
}
listado_motifs<-ultimo(matriz.compas,INT)

listado_motifs2<-NULL
elementos<-length(listado_motifs)
	for (i in 1:elementos){	
		if (nrow(listado_motifs[[i]])>1){
		listado_motifs2[[i]]=listado_motifs[[i]]
		}
	}

listado_motifs2_test <- as.matrix(do.call(rbind, listado_motifs2)) # this merges the separate edgelists into one
listado_motifs2_test ####if error message appears is because did not find motifs. desestimar lo posteriior


mot<-as.data.frame(listado_motifs2_test) 

write.table(mot, file = "poli_549.csv", sep = ",",
           eol = "\n", dec = ".", row.names = F, col.names = T)


motif_frequency<-sum(mot$low.level!="Glycine_max")
motif_frequency

###########################################
####***MOTIFS IN TRIPARTITE NETWORKS***####
###########################################
#to study parasitism motifs

library(tidyverse)
planilla<-read.table("definitiva_ordenada.csv", sep=",",header=T)
planilla<-read.table("definitiva_ordenada2.csv", sep=",",header=T)

#Selection by Field
by.field<-planilla[planilla$Field=="540",]###voy cambiando numero aca537 543

#Select herbivoty + parasitoidism interations togheter
INT<-by.field[by.field$interaction_type=="herbivory" |  by.field$interaction_type=="parasitoidism",]
colnames(INT)=c("Field","lower.taxon","upper.taxon","guild1","guild2","interaction_type","weight")
INT

motif.detector_ac(edgelist=INT,crop.plant="Glycine_max")

## A function to detect the apparent competition (ac) between herbivores of in- and off-crop plants
motif.detector_ac <- function(edgelist,crop.plant){
  
  options(warn = -1)
  
  ## 1. Detect the herbivores interacting with the crop plants of interest
  herb_en_motif <- NULL
  for (i in 1:length(crop.plant)){
    herb_en_motif[[i]] <- edgelist[edgelist$lower.taxon == crop.plant[i],] # Hebivores interacting with the crop plants of interest
  }
  herbivores_mat <- as.matrix(do.call(rbind, herb_en_motif)) # Bind the lists of interactions together
  herbivores <- unique(herbivores_mat[,3]) # Names of the upper taxon (the crop plant herbivores)
  
  
  ## 2. Detect the parasitoids of the herbivores on the crop plants of interest
  para_en_motif <- NULL
  for (j in 1:length(herbivores)){ 
    para_en_motif[[j]] <- edgelist[edgelist$lower.taxon == herbivores[j],]
  }
  parasitoids_mat <- as.matrix(do.call(rbind, para_en_motif)) # Bind the lists of interactions together
  parasitoids <- unique(parasitoids_mat[,3]) # Names of the upper taxon (the parasitoids of the herbivores)
  
  
  ## 3. Detect the shared herbivores of the parasitoids of the herbivores feeding on crop plants
  shared_herb_en_motif <- NULL
  for (k in 1:length(parasitoids)){ 
    shared_herb <- edgelist[edgelist$upper.taxon == parasitoids[k],]
    if(nrow(shared_herb)>0){
      shared_herb_en_motif[[k]] <- shared_herb  
    } else 
      shared_herb_en_motif[[k]] <- NULL
  }
  shared.herbivores_mat <- as.matrix(do.call(rbind, shared_herb_en_motif)) # Bind the lists of interactions together
  shared.herbivores <- unique(shared.herbivores_mat[,2]) # Names of the lower taxon (the shared herbivores of the parasitoids of the crop plant herbivores)
  
  ## 4. Detect the shared plants of herbivores of the parasitoids of the herbivores feeding on crop plants
  shared.host.plants_en_motif <- NULL
  for (l in 1:length(shared.herbivores)){ 
    shared.host.plants_en_motif[[l]] <- edgelist[edgelist$upper.taxon == shared.herbivores[l],]
  }
  shared.host.plants_mat <- as.matrix(do.call(rbind, shared.host.plants_en_motif)) # Bind the lists of interactions together
  shared.host.plants <- unique(shared.host.plants_mat[,2]) # Names of the lower taxon (the shared host plants of the shared herbivores of the parasitoids of the crop plant herbivores)
  
  ## 5. Collate all of the interactions taking part in the motifs
  motif_interactions <- rbind(herbivores_mat, 
                              parasitoids_mat[which(parasitoids_mat[,3] == shared.herbivores_mat[,3]),], # Remove the parasitoids that are not shared with shared plant herbivores
                              shared.herbivores_mat, 
                              shared.host.plants_mat[which(shared.host.plants_mat[,3] != herbivores_mat[,3]),]) # Remove the host plant-herbivore interactions not with shared herbivores
  motif_interactions <- distinct(data.frame(motif_interactions))
  
    ## 7. Report the results of the search
  return(motif_interactions)
  
}