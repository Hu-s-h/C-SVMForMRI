# C-SVMForMRI
AD classification by using c-SVM based on SGL1/2.

First, enter the PreProcessing folder and run batchPreProcessing.m(or run ac-pc.m and batch_job.m) to preprocess the sMRI data;

Then, enter the Extract_Feacture folder and run ExtractFeature_SPM.m for feature extraction;

If you want to get the ac-SLIC-AAL template, please run RunMySLIC.m in the MySLIC folder;

Finally, enter the Classfication folder and run runFun.m for AD classification. If you want to run separately the effect of fixed hyperparameters on classification, you can run testFun.m or SeparateFun.m.
